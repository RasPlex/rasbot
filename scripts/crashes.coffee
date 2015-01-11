fs = require "fs"
path = require "path"
zlib = require 'zlib'
mkdirp = require 'mkdirp'
base64 = require 'base64'

module.exports = (robot) ->

  robot.router.post '/crashes', (req, res) ->
    robot.logger.debug JSON.stringify req.query
    robot.logger.debug JSON.stringify req.params
    if 'dumpfileb64' of req.body and
       'version' of req.body
      version = req.body['version']
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

