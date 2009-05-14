require 'rubygems'
require 'simple-rss'
require 'net/https'

class Unfuddle < CampfireBot::Plugin
  at_interval 2.minutes, :fetch_rss
  on_command 'unfuddle', :fetch_rss

  def initialize
    @last_item = 12.hours.ago
    @http = Net::HTTP.new(bot.config['unfuddle_domain'], bot.config['unfuddle_port'])

    if bot.config['unfuddle_port'] == 443
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end

  def fetch_rss(msg)
    feed = SimpleRSS.parse(@http.get(bot.config['unfuddle_rss_path']).body)

    feed.items.each do |item|
      msg.speak "#{item.title} #{item.link}" if item.pubDate > @last_item
    end

    @last_item = feed.items.first.pubDate
  rescue => e
    msg.speak e
  end
end
