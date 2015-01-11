# Description:
#   This module is for utility functions internal to hubot, including
#   monkey patches to hubot core where necessary.
#
# Configuration:
#   MESSAGE_MAX_LENGTH - The maximum number of characters before a message will be DM'd instead
#   MESSAGE_MAX_LINES - The maximum number of lines before a message will be DM'd instead


max_length = parseInt process.env.MESSAGE_MAX_LENGTH, 10
max_lines  = parseInt process.env.MESSAGE_MAX_LINES, 10
max_length = 500 if isNaN max_length
max_lines  = 10 if isNaN max_lines

module.exports = (robot) ->

  robot.Response.prototype.send = (strings...) ->
    length = 0
    lines = 0
    length += string.length for string in strings
    lines += string.split('\n').length for string in strings

    roomEnvelope =
      room: @message.room
      user: @message.user
      message: @message

    if length > max_length or lines > max_lines
      robot.logger.debug """Message will be sent directly, it has #{lines} lines and #{length} chars,
                         exceeds max lines (#{max_lines}) or max length (#{max_length})"""

      @robot.adapter.reply roomEnvelope, strings...
    else
      @robot.adapter.send roomEnvelope, strings...

