# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
module.exports = (robot) ->

  robot.router.get '/install', (req, res) ->
    releases = []
    releases.push release for version,release of robot.github.releases['stable']
    releases.push release for version,release of robot.github.releases['prerelease']
    res.send JSON.stringify releases
  #
  # robot.error (err, msg) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if msg?
  #     msg.reply "DOES NOT COMPUTE"
  #
