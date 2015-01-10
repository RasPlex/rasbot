
eco = require "eco"
fs  = require "fs"

module.exports = (robot) ->

  robot.router.get '/update', (req, res) ->
    template = fs.readFileSync __dirname + "../views/update.eco", "utf-8"
    eco.render template, releases

