# Description:
#   Service install requests
#
# Author
#   dalehamel
#

Sequelize = require 'sequelize'

DEVICES =
  RPi: "Raspberry Pi"
  RPi2: "Raspberry Pi2"

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
    device = req.query['device'] || 'RPi'

    releases = []

    for version,release of robot.github.releases['stable']
      if device of release['devices']
        obj = {
          version: release['version']
          notes: release['notes']
          install_url: release['devices'][device]['install_url']
          install_sum: release['devices'][device]['install_sum']
        }
        releases.push obj

    for version,release of robot.github.releases['prerelease']
      if device of release['devices']
        obj = {
          version: release['version']
          notes: release['notes']
          install_url: release['devices'][device]['install_url']
          install_sum: release['devices'][device]['install_sum']
        }
        releases.push obj

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

  robot.router.get '/devices', (req, res) ->
    devices = []
    for release, data of robot.github.releases
      for version, version_data of data
        for device, device_data of version_data['devices']
          if device of DEVICES
            devices.push {id:device, name:DEVICES[device]} if (item for item in devices when item['id'] is device).length == 0

    res.send JSON.stringify devices
    res.end()
