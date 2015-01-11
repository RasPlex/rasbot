# Description:
#   Run curl commands
#
# Commands:
#   hubot curl [command] - run a curl command
#
# Author
#   dalehamel


module.exports = (robot) ->

  robot.respond /curl\s+(.*)/, (msg) ->
    command = msg.match[1]

    @exec = require('child_process').exec
    @exec "curl -s #{command}", (error, stdout, stderr) ->
      msg.send error if error?
      msg.send stdout if stdout?
      msg.send stderr if stderr?
