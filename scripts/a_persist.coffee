fs        = require "fs"
path      = require "path"
Sequelize = require "sequelize"

env       = process.env.NODE_ENV || "development"
config    = require(__dirname + '/../config/config.json')[env]
password  = process.env.HUBOT_MYSQL_PASS || config.password
config.password = password


module.exports = (robot) ->
  robot.orm = new Sequelize config.database, config.username, config.password, config.options
  robot.logger.debug "Cretaed the ORM with #{JSON.stringify config}"
