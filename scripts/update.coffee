# Description:
#   Service update requests, and manage the whitelist for the beta channel
#
# Commands:
#   hubot whitelist show - show the whitelisted users
#   hubot whitelist add [user] [serial]  - whitelist a given serial for a user
#   hubot whitelist remove [user] [serial]  - remove a whitelisted serial for a user
#
# Author
#   dalehamel


eco  = require "eco"
fs   = require "fs"
path = require 'path'
moment = require 'moment'

Sequelize = require 'sequelize'

channels = {
  "16":"stable",
  "2":"prerelease",
  "4":"beta"
}

module.exports = (robot) ->

  class Whitelist

    add: (user, serial) ->
      whitelist = robot.brain.get('whitelist') || {}
      whitelist[user] = [] unless user of whitelist
      whitelist[user].push serial
      robot.brain.set('whitelist', whitelist )
      return true

    remove: (user, serialToRemove) ->
      whitelist = robot.brain.get('whitelist') || {}
      newlist = whitelist[user].filter (serial) -> serial isnt serialToRemove
      whitelist[user] = newlist
      robot.brain.set('whitelist', whitelist )
      return true

    get: ->
      return robot.brain.get('whitelist')

  robot.UpdateRequest = robot.orm.define 'UpdateRequest', {
    serial:  { type: Sequelize.STRING(50), allowNull: false }
    hwrev:   { type: Sequelize.STRING(50), allowNull: false }
    ipaddr:  { type: Sequelize.STRING(50), allowNull: false }
    version: { type: Sequelize.STRING(50), allowNull: false }
    channel: { type: Sequelize.STRING(50), allowNull: false }
    time:    { type: Sequelize.DATE, allowNull: false }
  },
  { tableName: 'update_requests', timestamps: false }

  robot.UpdateCompleted = robot.orm.define 'UpdateCompleted', {
    serial:     { type: Sequelize.STRING(50), allowNull: false }
    hwrev:      { type: Sequelize.STRING(50), allowNull: false }
    ipaddr:     { type: Sequelize.STRING(50), allowNull: false }
    version:    { type: Sequelize.STRING(50), allowNull: false }
    oldversion: { type: Sequelize.STRING(50), allowNull: false }
    channel:    { type: Sequelize.STRING(50), allowNull: false }
    time:       { type: Sequelize.DATE, allowNull: false }
  },
  { tableName: 'update_completeds', timestamps: false }

  intVersion = (version) ->
    return 1000000 if version.match('wip')? # never update wip
    version = version.replace /\D/g, ''
    try
      version = parseInt version,10
    catch
      version = -1
    version = -1 if isNaN version
    return version

  robot.whitelist = new Whitelist
  robot.orm.sync()
  robot.updateTemplate = fs.readFileSync path.dirname(__dirname) + "/views/update.eco", "utf-8"

  robot.router.get '/update', (req, res) ->
    if 'channel' of req.query and 'serial' of req.query \
    and 'revision' of req.query and 'version' of req.query

      addr = req.headers['x-forwarded-for'] || req.connection.remoteAddress

      channel = channels[req.query['channel']]

      releases = []
      whitelist = []
      for user,serials of robot.whitelist.get()
        whitelist = whitelist.concat serials

      for version,release of robot.github.releases['stable']
        if intVersion(version) > intVersion(req.query['version'])
          releases.push release

      if channel == 'prerelease'
        for version,release of robot.github.releases['prerelease']
          if intVersion(version) > intVersion(req.query['version'])
            releases.push release

      if channel == 'beta' and req.query['serial']? and req.query['serial'] in whitelist
        for version,release of robot.github.releases['beta']
          if intVersion(version) > intVersion(req.query['version'])
            releases.push release

      update_req = robot.UpdateRequest.build({
        serial:  req.query['serial']
        hwrev:   req.query['revision']
        version: req.query['version']
        channel: req.query['channel']
        ipaddr:  addr
        time:    new Date
      })

      update_req.validate()
      .success (err) ->
        if err?
          robot.logger.debug "Update request invalid, #{JSON.stringify err}"

      update_req.save()
      .complete (err) ->
        if err?
          robot.logger.debug "Update request couldn't be saved, #{JSON.stringify err}"
        else
          robot.logger.debug "Update request saved."

      update_xml = eco.render robot.updateTemplate, releases: releases, moment:moment
      res.send update_xml

    else
      res.send "Missing required parameters"

    res.end()

  robot.router.get '/updated', (req, res) ->
    if 'channel' of req.query and 'serial' of req.query \
    and 'revision' of req.query and 'version' of req.query \
    and 'fromVersion' of req.query

      addr = req.headers['x-forwarded-for'] || req.connection.remoteAddress

      updated_req = robot.UpdateCompleted.build({
        serial:     req.query['serial']
        hwrev:      req.query['revision']
        version:    req.query['version']
        oldversion: req.query['fromVersion']
        channel:    req.query['channel']
        ipaddr:     addr
        time:       new Date
      })

      updated_req.validate()
      .success (err) ->
        if err?
          robot.logger.debug "Update completed request invalid, #{JSON.stringify err}"

      updated_req.save()
      .complete (err) ->
        if err?
          robot.logger.debug "Update completed request couldn't be saved, #{JSON.stringify err}"
        else
          robot.logger.debug "Update completed request saved."

      res.send "Thanks for updating"

    else
      res.send "Missing required parameters"

    res.end()

  robot.respond /whitelist\s+show/, (msg) ->
    msg.send """Hi #{msg.message.user.name}, the following serials are whitelisted:
    #{ ("- #{user}, has #{if serials.length >0 then serials.join(',') else "no serials registered"}" for user, serials of robot.whitelist.get() ).join('\n')}
    """

  robot.respond /whitelist\s+add\s+(\S+)\s+(\S+)/, (msg) ->
    user = msg.match[1]
    serial = msg.match[2]
    return msg.send "Hmm... #{serial} doesn't look like a correct serial" unless serial.length is 16
    return msg.send "Added!" if robot.whitelist.add user, serial


  robot.respond /whitelist\s+remove\s+(\S+)\s+(\S+)/, (msg) ->
    user = msg.match[1]
    serial = msg.match[2]
    return msg.send "Hmm... #{serial} doesn't look like a correct serial" unless serial.length is 16
    return msg.send "Removed!" if robot.whitelist.remove user, serial

