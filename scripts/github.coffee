# Description:
#   Synchronizes releases with github
#
# Configuration:
#   HUBOT_GITHUB_TOKEN - A token that allows access to the repo containing the releases
#   HUBOT_GITHUB_TICK - How frequently ( in minutes ) to check for update. Don't set too low, or you'll get throttled by github
#
# Commands:
#   hubot update releases - Force an update instead of waiting for the next update tick
#   hubot releases - List the releases on each channel
#
# Author
#   dalehamel
#
# Notes:


Yaml = require 'js-yaml'
GitHubApi = require "github"
CronJob = require('cron').CronJob
moment = require 'moment'

config =
  token:          process.env.HUBOT_GITHUB_TOKEN
  tick:           process.env.HUBOT_GITHUB_TICK

module.exports = (robot) ->

  class Github

    constructor: ->
      @github = new GitHubApi {version: "3.0.0", protocol: "https", host: "api.github.com"}
      if config.token?
        @github.authenticate {type: "token", token: config.token}
      @releases = {}
      new CronJob("00 */#{if config.tick? then config.tick else 5} * * * *",@updateReleases,null,true,'UTC')

    updateReleases: ->
      robot.github.github.releases.listReleases {owner: 'RasPlex', repo: 'RasPlex' }, (err,newReleases) ->
        releases = {}
        count=0
        for release in newReleases
          if 'body' of release
            count+=1
            bodytext = release['body']
            try
              body = Yaml.load bodytext
            catch error
              robot.logger.debug "#{error} on #{release['name']}"
              continue
            baseurl = release["html_url"].replace '/tag/', '/download/'
            channel = body['channel']
            version = release['name']
            time = if release['draft'] then new Date().toISOString() else new Date(release['published_at']).toISOString()
            releases[channel] = {} unless channel of releases
            releases[channel][version] =
              version: version
              channel: channel
              notes: body['changes'].join('\n')
              time: time
              id: count

            for asset in release['assets']
              if /img.gz/.test asset['name']
                releases[channel][version]['install_url'] = "#{baseurl}/#{asset['name']}"
                releases[channel][version]['install_count'] = asset['download_count']
              if /tar.gz/.test asset['name']
                releases[channel][version]['update_url'] = "#{baseurl}/#{asset['name']}"
                releases[channel][version]['update_count'] = asset['download_count']

            for field,data of body['install']
              for key, value of data

                switch key
                  when 'md5sum' then releases[channel][version]['install_sum'] = value
                  when 'url' then releases[channel][version]['install_url'] = value

            for field, data of body['update']
              for key, value of data

                switch key
                  when 'shasum' then releases[channel][version]['update_sum'] = value
                  when 'url' then releases[channel][version]['update_url'] = value

            releases[channel][version]['autoupdate'] = 'update_url' of releases[channel][version]

        robot.github.releases = releases

  robot.github = new Github
  robot.github.updateReleases()

  robot.respond /update\srelease(s)?/, (msg) ->
    robot.github.updateReleases()
    msg.send "Ok, #{msg.message.user.name}, the releases have been updated"

  robot.respond /releases/, (msg) ->
    msg.send """Hi #{msg.message.user.name}, these are the active releases:
    stable:
    #{ ("- #{version}, published at #{moment(data['time']).format(
        'YYYY-MM-DD HH:MM:SS UTC')
        }, U:#{data['update_count']}, D:#{data['install_count']}" for version, data of robot.github.releases['stable']).join('\n')}
    prerelease:
    #{ ("- #{version}, published at #{moment(data['time']).format(
        'YYYY-MM-DD HH:MM:SS UTC')
        }, U:#{data['update_count']}, D:#{data['install_count']}" for version, data of robot.github.releases['prerelease'] ).join('\n')}
    beta:
    #{ ("- #{version}, published at #{data['time']}" for version, data of robot.github.releases['beta'] ).join('\n')}
    """

