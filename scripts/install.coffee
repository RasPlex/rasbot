# Description:
#   Service install requests
#
# Author
#   dalehamel
#

Sequelize = require 'sequelize'
module.exports = (robot) ->

  robot.InstallRequest = robot.orm.define 'InstallRequest', {
    ipaddr:   { type: Sequelize.STRING(50), allowNull: false }
    platform: { type: Sequelize.STRING(50), allowNull: false }
    time:     { type: Sequelize.DATE, allowNull: false }
  },
  { tableName: 'install_requests', timestamps: false }

  robot.orm.sync()

  robot.router.get '/install', (req, res) ->

    addr = req.headers['x-forwarded-for'] || req.connection.remoteAddress
    platform = req.query['platform'] || 'unknown'

    releases = []
    releases.push release for version,release of robot.github.releases['stable']
    releases.push release for version,release of robot.github.releases['prerelease']

    install_req = robot.InstallRequest.build({
      ipaddr:    addr
      platform:  platform
      time:      new Date
    })

    install_req.validate()
    .success (err) ->
      if err?
        robot.logger.debug "Install request invalid, #{JSON.stringify err}"

    install_req.save()
    .complete (err) ->
      if err?
        robot.logger.debug "Install request couldn't be saved, #{JSON.stringify err}"
      else
        robot.logger.debug "Install request saved."

    res.send JSON.stringify releases
    res.end()
