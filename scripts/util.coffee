# Description:
#   This module is for utility functions internal to hubot, including
#   monkey patches to hubot core where necessary.
#

module.exports = (robot) ->

  # Allows for a message to be sent directly back to a given user
  # Monkeypatch the class directly, since it's not yet instantiated
  robot.Response.prototype.directSend = (strings...) ->
    envelope =
      room: @message.user.name
      user: @message.user
      message: @message
    try
      @robot.adapter.send envelope, strings...
    catch error
      envelope =
        room: @message.room
        user: @message.user
        message: @message
      cantsend = """I'm so sorry @#{@message.user.name}, but this message is too long for me to send to you without spamming the channel.
                   Please start a direct message with me and try your query again. (Slack won't let me DM you unless you've DM'd me before)."""
      @robot.adapter.send envelope, cantsend
