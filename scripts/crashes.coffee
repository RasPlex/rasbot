fs = require "fs"
path = require "path"
zlib = require 'zlib'
mkdirp = require 'mkdirp'
base64 = require 'base64'
Sequelize = require 'sequelize'

module.exports = (robot) ->

  Crash = robot.orm.define 'Crash', {
    id:                 { type: Sequelize.INTEGER(10), allowNull: false, autoIncrement: true }
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
    if ('dumpfileb64' of req.body) and ('version' of req.query) and ('serial' of req.query) and ('revision' of req.query)
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
      res.send "#{id}"
    else
      res.send "Invalid crash dump"
    res.end()

