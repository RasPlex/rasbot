
eco  = require "eco"
fs   = require "fs"
path = require 'path'
moment = require 'moment'

config =
  whitelist: if process.env.HUBOT_BETA_WHITELIST? then process.env.HUBOT_BETA_WHITELIST.split(',') else []

channels = {
  "16":"stable",
  "2":"prerelease",
  "4":"beta"
}

module.exports = (robot) ->

  robot.updateTemplate = fs.readFileSync path.dirname(__dirname) + "/views/update.eco", "utf-8"
  robot.router.get '/update', (req, res) ->
    if 'channel' of req.query
      channel = channels[req.query['channel']]
      robot.logger.debug "Getting updates for #{channel}"
      releases = []
      releases.push release for version,release of robot.github.releases['stable']
      if channel == 'prerelease'
        releases.push release for version,release of robot.github.releases['prerelease']
      if channel == 'beta' and req.query['serial']? and req.query['serial'] in config.whitelist
        releases.push release for version,release of robot.github.releases['beta']

      update_xml = eco.render robot.updateTemplate, releases: releases, moment:moment
      res.send update_xml

  robot.respond /whitelist/, (msg) ->
    msg.send "Hi #{msg.message.user.name}, the following serials are whitelisted: #{config.whitelist.join('\n')}"
