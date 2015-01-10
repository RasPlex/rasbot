
Yaml = require 'js-yaml'
GitHubApi = require "github"
CronJob = require('cron').CronJob
moment = require 'moment'
posix = require 'posix'

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
        for release in newReleases
          if 'body' of release
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

            for asset in release['assets']
              if /img.gz/.test asset['name']
                releases[channel][version]['install_url'] = "#{baseurl}/#{asset['name']}"
              if /tar.gz/.test asset['name']
                releases[channel][version]['update_url'] = "#{baseurl}/#{asset['name']}"

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

  robot.respond /releases/, (msg) ->
    msg.send JSON.stringify robot.github.releases

