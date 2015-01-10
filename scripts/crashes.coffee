fs = require "fs"
path = require "path"
uuid = require 'node-uuid'
base64 = require 'base64'

module.exports = (robot) ->

  robot.router.post '/crashes', (req, res) ->
    if 'dumpfileb64' of req.body
      id = uuid.v1()
      crashpath = path.dirname(__dirname) + "/crashdata/crash-#{id}"
      robot.logger.debug "Creating new crash #{crashpath}"
      fs.writeFile crashpath, base64.decode(req.body['dumpfileb64']), (error) ->
        robot.logger.error("Error writing file", error) if error
      res.send id
    else
      res.send "Invalid crash dump"
    res.end()

