# Description:
#   This module is for utility functions internal to hubot, including
#   monkey patches to hubot core where necessary.
#
# Configuration:
#   MESSAG_MAX_LENGTH - The maximum number of characters before a message will be DM'd instead
#   MESSAG_MAX_LINES - The maximum number of lines before a message will be DM'd instead


max_length = parseInt process.env.MESSAGE_MAX_LENGTH, 10
max_lines  = parseInt process.env.MESSAGE_MAX_LINES, 10
max_length = 500 if isNaN max_length
max_lines  = 10 if isNaN max_lines

module.exports = (robot) ->

  trySend = (robot, message, direct, room, strings...) ->
    try
      robot.adapter.send direct, strings...
    catch error
      cantsend = """I'm so sorry @#{message.user.name}, but this message is too long for me to send to you without spamming the channel.
                   Please start a direct message with me and try your query again. (Slack won't let me DM you unless you've DM'd me before)."""
      robot.adapter.send room, cantsend


  robot.Response.prototype.send = (strings...) ->
    length = 0
    lines = 0
    length += string.length for string in strings
    lines += string.split('\n').length for string in strings

    directEnvelope =
      room: @message.user.name
      user: @message.user
      message: @message

    roomEnvelope =
      room: @message.room
      user: @message.user
      message: @message

    if length > max_length or lines > max_lines
      robot.logger.debug """Message will be sent directly, it has #{lines} lines and #{length} chars,
                         exceeds max lines (#{max_lines}) or max length (#{max_length})"""

      trySend @robot, @message, directEnvelope, roomEnvelope, strings...
    else
      @robot.adapter.send roomEnvelope, strings...

  # Allows for a message to be sent directly back to a given user
  # Monkeypatch the class directly, since it's not yet instantiated
  robot.Response.prototype.directSend = (strings...) ->
    directEnvelope =
      room: @message.user.name
      user: @message.user
      message: @message

    roomEnvelope =
      room: @message.room
      user: @message.user
      message: @message

    trySend @robot, @message, directEnvelope, roomEnvelope, strings...
