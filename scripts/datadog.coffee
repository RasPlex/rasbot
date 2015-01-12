# Description:
#   Query Datadog using Hubot.
#
# Configuration:
#   HUBOT_DATADOG_APIKEY - Your Datadog API key
#   HUBOT_DATADOG_APPKEY - Your Datadog app Key
#
# Commands:
#   hubot (datadog|dd|dog|graph) [dashboard] [graph] - snapshot a specific graph from a dashboard that you've already told hubot about.
#   hubot (datadog|dd|dog) graphs [query]- Show the available graphs, optionally matching a query regex
#   hubot (datadog|dd|dog) graph me <amount><unit> <metric query> - Queries for a graph snapshot
#   hubot (datadog|dd|dog) metric search <metric query> - Queries for a list of matching metrics
#
# Author
#   tombell
#
# Notes:
#   * Built using https://www.npmjs.com/package/dogapi
#   * Forked from https://github.com/zestia/hubot-datadog

dog    = require 'dogapi'
moment = require 'moment'

module.exports = (robot) ->

  unless process.env.HUBOT_DATADOG_APIKEY?
    return robot.logger.error "HUBOT_DATADOG_APIKEY env var is not set"

  unless process.env.HUBOT_DATADOG_APPKEY?
    return robot.logger.error "HUBOT_DATADOG_APPKEY env var is not set"

  client = new dog {
    api_key: process.env.HUBOT_DATADOG_APIKEY
    app_key: process.env.HUBOT_DATADOG_APPKEY
  }

  class DatadogGraphs

    newdash: (slug, id) ->
      graphs = robot.brain.get('graphs') || {}
      return false if slug of graphs
      graphs[slug] = {dashboard: id, graphs: {}}
      robot.brain.set('graphs', graphs )
      return true

    removedash: (slug) ->
      graphs = robot.brain.get('graphs') || {}
      return false unless slug of graphs
      delete graphs[slug]
      return true

    add: (dashslug, slug, title) ->
      graphs = robot.brain.get('graphs') || {}
      return false unless dashslug of graphs
      return false if dashslug of graphs and slug of graphs[dashslug]['graphs']
      graphs[dashslug]['graphs'][slug] = {title: title}
      robot.brain.set('graphs', graphs )
      return true

    remove: (dashslug, slug) ->
      graphs = robot.brain.get('graphs') || {}
      return false unless dashslug of graphs and slug of graphs[dashslug]['graphs']
      delete graphs[dashslug]['graphs'][slug]
      robot.brain.set('graphs', graphs )
      return true

    get: ->
      return robot.brain.get('graphs')

  robot.ddgraphs = new DatadogGraphs

  SPECIAL_REGEXP_CHARS = /[|\\{}()[\]^$+*?.]/g
  escapeRegexpString = (str) ->
    return str.replace(SPECIAL_REGEXP_CHARS, '\\$&')

  robot.respond /(dd|datadog|dog)+\s+graphs(\s*)(.*)/i, (msg) ->
    msg.message.finish()
    query = msg.match[3]
    queryexp = ///#{query}///i

    matchstr = if query.length>0 then " that match (#{query})" else ""
    message = "I know about these graphs#{matchstr}:\n"

    graphs = robot.ddgraphs.get()
    for dash,obj of graphs
      message += "#{dash} (no graphs yet)\n" if Object.keys(obj['graphs']).length == 0
      for graph,data of obj['graphs']
        graphline = "#{dash} #{graph} (#{data['title']})\n"
        if query.length > 0
          if queryexp.test graphline
            message += graphline
        else
          message += graphline
    message += "You can use '#{robot.name} dd [dashboard] [graph]' to view them."
    msg.directSend message

  robot.respond /(dd|datadog|dog)\s+new\s+dash(board)?\s+(\S+)\s+(\d+)/, (msg) ->
    msg.message.finish()
    dashslug = msg.match[3]
    id   = msg.match[4]
    added = robot.ddgraphs.newdash dashslug, id
    if added then msg.send "Added!" else msg.send "Sorry, I couldn't add the #{dashslug} dashboard"

  robot.respond /(dd|datadog|dog)\s+new\s+graph\s+(\S+)\s+(\S+)\s+(.+)/, (msg) ->
    msg.message.finish()
    dashslug = msg.match[2]
    slug     = msg.match[3]
    id       = msg.match[4]
    added = robot.ddgraphs.add dashslug, slug, id
    if added then msg.send "Added!" else msg.send "Sorry, I couldn't add the #{slug} graph to the #{dashslug} dashboard"

  robot.respond /(dd|datadog|dog)\s+(remove|rm|del|delete)\s+dash(board)?\s+(\S+)/, (msg) ->
    msg.message.finish()
    dashslug = msg.match[4]
    removed = robot.ddgraphs.removedash dashslug
    if removed then msg.send "Removed!" else msg.send "Sorry, I couldn't remove the #{dashslug} dashboard"

  robot.respond /(dd|datadog|dog)\s+(remove|rm|del|delete)\s+graph\s+(\S+)\s+(\S+)/, (msg) ->
    msg.message.finish()
    dashslug = msg.match[3]
    slug     = msg.match[4]
    removed = robot.ddgraphs.remove dashslug, slug
    if removed then msg.send "Removed!" else msg.send "Sorry, I couldn't remove the #{slug} graph from the #{dashslug} dashboard"

  robot.respond /(dd|datadog|dog|graph)\s+(\S+)\s+(\S+)/i, (msg) ->
    dash = msg.match[2]
    graph = msg.match[3]

    graphs = robot.ddgraphs.get()
    unless dash of graphs
      return msg.send "Sorry, no one told me how about the #{dash} dashboard yet :("
    unless graph of graphs[dash]['graphs']
      return msg.send "Sorry, no one told me how to get the graph for #{graph} yet :("

    title = graphs[dash]['graphs'][graph]['title']
    dashboard = graphs[dash]['dashboard']

    client.get_dashboard dashboard, (err, result, status) ->
      return msg.send "Could not get the graph dashboard #{err}" if err?

      definitions = ( definition for definition in result['dash']['graphs'] when definition['title'] == title )
      variables = result['dash']['template_variables']
      return msg.send "Uh oh, I couldn't find a graph for #{title} on dashboard #{dashboard}, maybe it's been renamed?" unless definitions.length > 0

      graph_def = JSON.stringify definitions[0]["definition"]

      if variables?
        for variable in variables
          name = escapeRegexpString variable['name']
          robot.logger.debug "Replacing #{name} with #{variable['default']}"
          graph_def = graph_def.replace ///\$#{name}///g, variable['default']

      now = moment()
      end = now.unix()
      start = now.subtract(1,'h').unix()

      snapshot = {
        graph_def: graph_def
        start: start
        end: end
      }

      # datadog posts back the URL before it's actually ready.
      # We must poll befor putting it into the chat.
      client.add_snapshot_from_def snapshot, (err, result, status) ->
        check_status = (url) ->
          client.snapshot_status result['snapshot_url'], (err,result,status) ->
            check_status url unless result['status_code'] == 200
            if result['status_code'] == 200
              end = moment()
              elapsed = end - start
              msg.send "Here's your graph for #{dash} #{graph}, #{msg.message.user.name}: #{url} (took #{elapsed/1000}s)"

        start = moment()
        check_status result['snapshot_url']


  robot.respond /(dd|datadog|dog)+\s+graph(\s*me)?\s+(\d+)([smhdwMy])\s+(.*)/i, (msg) ->
    msg.message.finish()
    time = msg.match[2]
    unit = msg.match[3]
    metric = msg.match[4]

    now = moment()
    end = now.unix()
    start = now.subtract(unit, time).unix()

    snapshot = {
      metric_query: metric
      start: start
      end: end
    }

    client.add_snapshot snapshot, (err, result, status) ->
      return msg.send "Could not generate the graph snapshot: #{err}" if err?

      setTimeout ->
        msg.send result['snapshot_url']
      , 3000

  robot.respond /(dd|datadog|dog)+\s+metric(s)?\s+search\s+(.*)/i, (msg) ->
    msg.message.finish()
    metric = msg.match[2]

    client.search metric, (err, result, status) ->
      msg.send "Could not fetch search results: #{err}" if err?

      metrics = result['results']['metrics']
      msg.send "I found the following results:", metrics.join("\n")

