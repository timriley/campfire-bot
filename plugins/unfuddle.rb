# Unfuddle RSS echo plugin. Uses the following config.yml settings:
#
# unfuddle:
#   domain: you.unfuddle.com
#   rss_path: "/account/activity.rss?aak=aaaaaaaaaaaaabbbbbbbbccccccccddddddeeee0000"
#   port: 443
#   msg_filters:
#     - reassigned
#     - closed
#     - commented
#     - resolved

require 'rubygems'
require 'simple-rss'
require 'net/https'

class Unfuddle < CampfireBot::Plugin
  at_interval 2.minutes, :fetch_rss
  on_command 'unfuddle', :fetch_rss

  def initialize
    @last_item = 12.hours.ago
    @http = Net::HTTP.new(bot.config['unfuddle']['domain'], bot.config['unfuddle']['port'])

    if bot.config['unfuddle']['port'] == 443
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end

  def fetch_rss(msg)
    feed = SimpleRSS.parse(@http.get(bot.config['unfuddle']['rss_path']).body)

    feed.items.each do |item|
      msg.speak "#{item.title} #{item.link}" if published?(item) && !filtered?(item.title)
    end

    @last_item = feed.items.first.pubDate
  rescue => e
    msg.speak e
  end

  def published?(item)
    item.pubDate > @last_item
  end

  def filtered?(title)
    bot.config['unfuddle']['msg_filters'].each do |msg_filter|
      return true if send("#{msg_filter}?", title)
    end
    return false
  end

  def closed?(title)
    (title =~ /Closed Ticket:/) != nil
  end

  def reassigned?(title)
    (title =~ /Reassigned Ticket:/) != nil
  end

  def commented?(title)
    (title =~ /Created Ticket Comment:/) != nil
  end

  def resolved?(title)
    (title =~ /Resolved Ticket:/) != nil
  end
end
