# Description:
#   Store a log of everything
#
# Commands:
#   history (search|find|match|query) /[query]/i - search the history for a regex match (receive the answer in a DM)
#   history since [time][unit] - view log entries since time unit (ex 1m for 1 minute, 2h for 2 hours) (in a DM)
#   history tail [N] - view the most recent N log entries (defaults to 5) (in a DM)
#   history view - view the entire ops log (in a DM)
#
# Configuration:
#   HUBOT_HISTORY_ROOMS - comma separated list of rooms to record history in

# Notes:
#   * All responses with contents of the history are delivered
#     as direct messages to avoid spamming an entire channel.

moment = require 'moment'

rooms  = if process.env.HUBOT_HISTORY_ROOMS then process.env.HUBOT_HISTORY_ROOMS.split(',') else []

module.exports = (robot) ->

  class History

    add: (time, message, user) ->
      log = robot.brain.get('history') || {}
      log[time] = { 'message' : message, 'user' : user }
      robot.brain.set('history', log )

    get: (stamp=-1) ->
      stamp = -1 unless stamp?
      entries = []
      log = robot.brain.get('history') || {}
      keys = Object.keys(log).sort (a, b) -> a - b
      for k in keys
        if k > stamp
          entry = log[k]
          time = moment.unix(k).format('YYYY-MM-DD HH:mm:ss')
          entries.push "#{time} UTC : #{entry['message']} - @#{entry['user']}"
      return entries

  history = new History

  # Log everything
  robot.hear /(.*)/i, (msg) ->
    robot.logger.debug "#{msg.message.room} #{JSON.stringify rooms}"
    return unless msg.message.room of rooms

    message = msg.match[1]
    return if (message.replace /\s/g, '').length == 0
    now = moment().unix()
    history.add(now, message, msg.message.user.name)

  robot.hear /history\s+view/i, (msg) ->
    logs = history.get -1, -1
    robot.logger.debug 'view'
    msg.reply logs.join("\n")

  robot.hear /history\s+since\s+(\d+)([smhdwMy])/i, (msg) ->
    time = msg.match[1]
    unit = msg.match[2]

    now = moment()
    start = now.subtract(unit, time).unix()

    logs = history.get start

    msg.reply  logs.join("\n")

  robot.hear /history\s+tail\s*(\d*)/i, (msg) ->
    entries = msg.match[1]
    entries = 5 unless entries?

    logs = history.get()
    entries =  if entries >= logs.length then logs.length-1 else entries
    logs = logs[-entries..]

    msg.reply logs.join("\n")

  robot.hear /history\s+(search|find|match|query)+\s+(.*)/i, (msg) ->
    search = ///#{msg.match[2]}///i

    logs = history.get()
    entries = ( entry for entry in logs when search.test entry )

    header = if entries.length>0 then "The following log entries match your query:" else "No log entries match your query"

    msg.reply  "#{header}\n#{entries.join("\n")}"
