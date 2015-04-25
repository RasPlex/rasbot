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
        stats = {}
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
              devices: {}

            install_images = {}

            for field,data of body['install']
              for key, value of data
                switch field
                  when "RPi"
                    releases[channel][version]['devices'][field] = {} unless releases[channel][version]['devices'][field]?
                    for k,v of value
                      switch k
                        when 'file' then releases[channel][version]['devices'][field]['install_file'] = v
                        when 'md5sum' then releases[channel][version]['devices'][field]['install_sum'] = v
                        when 'url' then releases[channel][version]['devices'][field]['install_url'] = v

                  when "RPi2"
                    releases[channel][version]['devices'][field] = {} unless releases[channel][version]['devices'][field]?
                    for k,v of value
                      switch k
                        when 'file' then releases[channel][version]['devices'][field]['install_file'] = v
                        when 'md5sum' then releases[channel][version]['devices'][field]['install_sum'] = v
                        when 'url' then releases[channel][version]['devices'][field]['install_url'] = v

                  else
                    releases[channel][version]['devices']['RPi'] = {} unless releases[channel][version]['devices']['RPi']?
                    switch key
                      when 'file' then releases[channel][version]['devices']['RPi']['install_file'] = value
                      when 'md5sum' then releases[channel][version]['devices']['RPi']['install_sum'] = value
                      when 'url' then releases[channel][version]['devices']['RPi']['install_url'] = value

            for field, data of body['update']
              for key, value of data
                switch field
                  when "RPi"
                    releases[channel][version]['devices'][field] = {} unless releases[channel][version]['devices'][field]?
                    for k,v of value
                      switch k
                        when 'file' then releases[channel][version]['devices'][field]['update_file'] = v
                        when 'shasum' then releases[channel][version]['devices'][field]['update_sum'] = v
                        when 'url' then releases[channel][version]['devices'][field]['update_url'] = v

                  when "RPi2"
                    releases[channel][version]['devices'][field] = {} unless releases[channel][version]['devices'][field]?
                    for k,v of value
                      switch k
                        when 'file' then releases[channel][version]['devices'][field]['update_file'] = v
                        when 'shasum' then releases[channel][version]['devices'][field]['update_sum'] = v
                        when 'url' then releases[channel][version]['devices'][field]['update_url'] = v

                  else
                    releases[channel][version]['devices']['RPi'] = {} unless releases[channel][version]['devices']['RPi']?
                    switch key
                      when 'file' then releases[channel][version]['devices']['RPi']['update_file'] = value
                      when 'shasum' then releases[channel][version]['devices']['RPi']['update_sum'] = value
                      when 'url' then releases[channel][version]['devices']['RPi']['update_url'] = value

            stats[release['tag_name']] = { 'install' : {}, 'update' : {}}
            for asset in release['assets']
              if /img.gz/.test asset['name']
                for device, data of releases[channel][version]['devices']
                  if data['install_file'] == asset['name']
                    stats[release['tag_name']]['install'][device] = asset['download_count']
                    releases[channel][version]['devices'][device]['install_url'] = "#{baseurl}/#{asset['name']}" unless 'install_url' of data

              if /tar.gz/.test asset['name']
                for device, data of releases[channel][version]['devices']
                  if data['update_file'] == asset['name']
                    stats[release['tag_name']]['update'][device] = asset['download_count']
                    releases[channel][version]['devices'][device]['update_url'] = "#{baseurl}/#{asset['name']}" unless 'update_url' of data

            releases[channel][version]['autoupdate'] = 'update_url' of releases[channel][version]

        robot.github.stats = stats
        robot.github.releases = releases


  robot.github = new Github
  robot.github.updateReleases()

  formatRelease = (version, data) ->
    return """#{version}:
    \tinstalls: RPi1: #{data['install']['RPi']} #{if data['install']['RPi2'] then ", RPi2: #{data['install']['RPi2']}" else ""}
    \tupdates:  RPi1: #{data['update']['RPi']} #{if data['update']['RPi2'] then ", RPi2: #{data['update']['RPi2']}" else ""}
      """

  robot.respond /update\srelease(s)?/, (msg) ->
    robot.github.updateReleases()
    msg.send "Ok, #{msg.message.user.name}, the releases have been updated"
    robot.logger.debug JSON.stringify robot.github.releases

  robot.respond /releases/, (msg) ->
    msg.send """Hi #{msg.message.user.name}, these are the active releases:
    stable:
    #{ ("- #{version}, published at #{moment(data['time']).format(
        'YYYY-MM-DD HH:MM:SS UTC')
        }" for version, data of robot.github.releases['stable']).join('\n')}
    prerelease:
    #{ ("- #{version}, published at #{moment(data['time']).format(
        'YYYY-MM-DD HH:MM:SS UTC')
        }" for version, data of robot.github.releases['prerelease'] ).join('\n')}
    beta:
    #{ ("- #{version}, published at #{data['time']}" for version, data of robot.github.releases['beta'] ).join('\n')}
    """

  robot.respond /release\s+downloads\s*(\S+)?/, (msg) ->
    version = msg.match[1]
    if version and robot.github.stats[version]
      msg.send formatRelease(version, robot.github.stats[version])
    else
      releases = []
      for version, data of robot.github.stats
         releases.push formatRelease(version, data)
      msg.send releases.join('\n')
