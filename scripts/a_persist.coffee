# Description:
#   Provide an ORM on hubot for other scripts
#
# Author
#   dalehamel
#
# Notes:
#  * The 'a_' prefix is a hack that forces this script to be loaded first, so anything
#    else needing acces to an ORM well have it set up already.




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
