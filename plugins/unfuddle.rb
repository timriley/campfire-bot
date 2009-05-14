require 'rubygems'
require 'simple-rss'
require 'net/https'

class Unfuddle < CampfireBot::Plugin
  at_interval 2.minutes, :fetch_rss
  on_command 'unfuddle', :fetch_rss
  
  def initialize
    @last_item = 12.hours.ago
    @http = Net::HTTP.new('amc.unfuddle.com', 443)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def fetch_rss(msg)
    feed = @http.get(bot.config['unfuddle_rss_path'])

    rss = SimpleRSS.parse(feed.body)
    
    for item in rss.items
      msg.speak item.title + ' ' + item.link if item.pubDate > @last_item
    end
    
    @last_item = rss.items.first.pubDate
  end
end
