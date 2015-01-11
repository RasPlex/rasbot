# Description:
#   Provide stats
#
# Author
#   dalehamel
#
# Notes
#  * TO DO: actually implement this
#  * TO DO: imprement chat commands to ask for various stats


module.exports = (robot) ->

  robot.router.get '/json/stats', (req, res) ->

    res.set "Access-Control-Allow-Origin", "http://www.rasplex.com, https://www.rasplex.com"
    res.send {}

#def getStats(geo_db)
#  stats = {
#    :users => {
#      :days_ago =>{},
#      :total => 0,
#    },
#    :installs => {
#      :days_ago =>{},
#      :total => {},
#    },
#    :last_update => DateTime.now,
#
#  }
#  for lookback in (1..7).to_a.reverse
#    value = repository(:default).adapter.select('SELECT COUNT(DISTINCT serial) 
#                                                  FROM update_requests 
#                                                  WHERE time BETWEEN date_sub(now(),INTERVAL ? DAY) 
#                                                  AND date_sub(now(),INTERVAL ? DAY);', lookback, lookback-1)
#    stats[:users][:days_ago][lookback] = value
#  end
#
#  stats[:users][:total] = repository(:default).adapter.select('SELECT COUNT(DISTINCT serial) 
#                                                                FROM update_requests;')
#
#
#  for lookback in (1..7).to_a.reverse
#    value = repository(:default).adapter.select('SELECT platform, COUNT(DISTINCT ipaddr) 
#                                                  FROM install_requests 
#                                                  WHERE time BETWEEN date_sub(now(),INTERVAL ? DAY) 
#                                                  AND date_sub(now(),INTERVAL ? DAY)
#                                                  GROUP BY platform;', lookback, lookback-1)
#    stats[:installs][:days_ago][lookback] = {}
#    value.each do | platform |
#       stats[:installs][:days_ago][lookback][platform.platform] = platform["count(distinct ipaddr)"]
#    end
#  end
#
#  value = repository(:default).adapter.select('SELECT platform, COUNT(DISTINCT ipaddr) 
#                                                                  FROM install_requests
#                                                                  GROUP BY platform;')
#
#  value.each do | platform |
#     stats[:installs][:total][platform.platform] = platform["count(distinct ipaddr)"]
#  end
#

