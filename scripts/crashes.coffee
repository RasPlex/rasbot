# Description:
#   Receives crash dumps
#
# Commands:
#   hubot crash [id] - get the stack trace for a crash ID
#
# Author
#   dalehamel
#
# Notes:
#  * To do: process each dump as it's received if it's for a non retired release, make this dump data accessible
#  * To do: delete the dumps after they've been traced, and gzip the traces

fs = require "fs"
path = require "path"
zlib = require 'zlib'
mkdirp = require 'mkdirp'
base64 = require 'base64'
Sequelize = require 'sequelize'

module.exports = (robot) ->

  robot.Crash = robot.orm.define 'Crash', {
    version:            { type: Sequelize.STRING(100), allowNull: false }
    submitter_version:  { type: Sequelize.STRING(100), allowNull: false }
    crash_path:         { type: Sequelize.STRING(200), allowNull: false }
    serial:             { type: Sequelize.STRING(50), allowNull: false }
    hwrev:              { type: Sequelize.STRING(50), allowNull: false }
    ipaddr:             { type: Sequelize.STRING(50), allowNull: false }
    time:               { type: Sequelize.DATE, allowNull: false }
  },
  { tableName: 'crashes', timestamps: false }

  robot.orm.sync()

  robot.router.post '/crashes', (req, res) ->
    if 'dumpfileb64' of req.body and 'version' of req.query \
    and 'serial' of req.query and 'revision' of req.query \
    and 'submitter_version' of req.query

      addr = req.headers['x-forwarded-for'] || req.connection.remoteAddress
      version = req.query['version']
      countpath = path.dirname(__dirname) + "/crashdata/count"

      if fs.existsSync countpath
        data = fs.readFileSync countpath, "utf-8"
        count = parseInt data, 10
      else
        count = 0
      count++
      fs.writeFile countpath, count, (error) ->
        robot.logger.error("Error writing count file", error) if error

      id = count
      crashdir = path.dirname(__dirname) + "/crashdata/#{version}"
      mkdirp crashdir
      crashpath = "#{crashdir}/crash-#{id}"

      robot.logger.debug "Creating new crash #{crashpath}"
      fs.writeFile crashpath, base64.decode(req.body['dumpfileb64']), (error) ->
        robot.logger.error("Error writing file", error) if error

      crash = robot.Crash.build({
        serial:            req.query['serial']
        hwrev:             req.query['revision']
        version:           req.query['version']
        ipaddr:            addr
        time:              new Date
        crash_path:        crashpath
        submitter_version: req.query['submitter_version']
      })

      crash.validate()
      .success (err) ->
        if err?
          robot.logger.debug "Crash invalid, #{JSON.stringify err}"

      crash.save()
      .complete (err) ->
        if err?
          robot.logger.debug "Crash couldn't be saved, #{JSON.stringify err}"
        else
          robot.logger.debug "Crash request saved."

      res.send "#{id}"
    else
      res.send "Invalid crash dump"
    res.end()

