# Description:
#   Example scripts for you to examine and try out.
#
# Notes:

Sequelize = require 'sequelize'
module.exports = (robot) ->

  InstallRequest = robot.orm.define 'InstallRequest', {
    id:       { type: Sequelize.INTEGER(10), autoIncrement: true }
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
    res.send JSON.stringify releases
    res.end()
  #
  # robot.error (err, msg) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if msg?
  #     msg.reply "DOES NOT COMPUTE"
  #
