

eco  = require "eco"
fs   = require "fs"
path = require 'path'
moment = require 'moment'

Sequelize = require 'sequelize'

config =
  whitelist: if process.env.HUBOT_BETA_WHITELIST? then process.env.HUBOT_BETA_WHITELIST.split(',') else []

channels = {
  "16":"stable",
  "2":"prerelease",
  "4":"beta"
}

module.exports = (robot) ->

  UpdateRequest = robot.orm.define 'UpdateRequest', {
    serial:  { type: Sequelize.STRING(50), allowNull: false }
    hwrev:   { type: Sequelize.STRING(50), allowNull: false }
    ipaddr:  { type: Sequelize.STRING(50), allowNull: false }
    version: { type: Sequelize.STRING(50), allowNull: false }
    channel: { type: Sequelize.STRING(50), allowNull: false }
    time:    { type: Sequelize.DATE, allowNull: false }
  },
  { tableName: 'update_requests', timestamps: false }

  UpdateCompleted = robot.orm.define 'UpdateCompleted', {
    serial:     { type: Sequelize.STRING(50), allowNull: false }
    hwrev:      { type: Sequelize.STRING(50), allowNull: false }
    ipaddr:     { type: Sequelize.STRING(50), allowNull: false }
    version:    { type: Sequelize.STRING(50), allowNull: false }
    oldversion: { type: Sequelize.STRING(50), allowNull: false }
    channel:    { type: Sequelize.STRING(50), allowNull: false }
    time:       { type: Sequelize.DATE, allowNull: false }
  },
  { tableName: 'update_completeds', timestamps: false }

  robot.orm.sync()
  robot.updateTemplate = fs.readFileSync path.dirname(__dirname) + "/views/update.eco", "utf-8"

  robot.router.get '/update', (req, res) ->
    if 'channel' of req.query and 'serial' of req.query \
    and 'revision' of req.query and 'version' of req.query

      addr = req.headers['x-forwarded-for'] || req.connection.remoteAddress

      channel = channels[req.query['channel']]
      robot.logger.debug "Getting updates for #{channel}"

      releases = []
      releases.push release for version,release of robot.github.releases['stable']
      if channel == 'prerelease'
        releases.push release for version,release of robot.github.releases['prerelease']
      if channel == 'beta' and req.query['serial']? and req.query['serial'] in config.whitelist
        releases.push release for version,release of robot.github.releases['beta']

      update_req = UpdateRequest.build({
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

      updated_req = UpdateCompleted.build({
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


  robot.respond /whitelist/, (msg) ->
    msg.send "Hi #{msg.message.user.name}, the following serials are whitelisted: #{config.whitelist.join('\n')}"
