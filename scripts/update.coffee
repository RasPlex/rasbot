
eco  = require "eco"
fs   = require "fs"
path = require 'path'

module.exports = (robot) ->

  robot.router.get '/update', (req, res) ->
    releases = []
    releases.push release for version,release of robot.github.releases['stable']
    releases.push release for version,release of robot.github.releases['prerelease']

    template = fs.readFileSync path.dirname(__dirname) + "/views/update.eco", "utf-8"
    eco.render template, releases

