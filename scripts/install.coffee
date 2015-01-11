# Description:
#   Example scripts for you to examine and try out.
#
# Notes:

Sequelize = require 'sequelize'
module.exports = (robot) ->

  InstallRequest = robot.orm.define 'InstallRequest', {
    ipaddr:   { type: Sequelize.STRING(50), allowNull: false }
    platform: { type: Sequelize.STRING(50), allowNull: false }
    time:     { type: Sequelize.DATE, allowNull: false }
  },
  { tableName: 'install_requests', timestamps: false }

  robot.orm.sync()

  robot.router.get '/install', (req, res) ->

    releases = []
    releases.push release for version,release of robot.github.releases['stable']
    releases.push release for version,release of robot.github.releases['prerelease']

    platform = req.query['platform'] || 'unknown'
    install_req = InstallRequest.build({
      ipaddr:    addr
      platform:  platform
      time:      new Date
    })
    robot.logger.debug JSON.stringify update_req
    install_req.validate()
    .success (err) ->
      if err?
        robot.logger.debug "Install request invalid, #{JSON.stringify err}"
    install.save()
    .complete (err) ->
      if err?
        robot.logger.debug "Install request couldn't be saved, #{JSON.stringify err}"
      else
        robot.logger.debug "Install request saved."

    res.send JSON.stringify releases
    res.end()

