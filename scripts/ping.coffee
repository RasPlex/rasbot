# Description:
#   Provide a dump health check for pingdom
#
# Author
#   dalehamel
#


module.exports = (robot) ->

  robot.router.get '/', (req, res) ->
    res.send 'pong'

