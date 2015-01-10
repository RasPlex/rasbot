fs = require "fs"
uuid = require 'node-uuid'
base64 = require 'base64'

module.exports = (robot) ->

  robot.router.post '/crashes', (req, res) ->
    if req.params.dumpfileb64?
      crashpath = fs.readFileSync path.dirname(__dirname) + "crash-#{uuid.v1()}"
      robot.logger.debug "Creating new crash #{crashpath}"
      fs.writeFile crashpath, base64.decode(req.params.dumpfileb64), (error) ->
        robot.logger.error("Error writing file", error) if error

