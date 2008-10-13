require 'rio'
require 'hpricot'
require 'ostruct'
require 'time'
require 'htmlentities'
require 'fileutils'

# The workings of this plugin come directly from http://github.com/paulca/twitter2campfire
# Thanks to Paul Campbell and Contrast! <http://www.contrast.ie/>

class TwitterEcho < PluginBase
  
  at_interval 2.minutes, :echo_tweets
  
  def initialize
    @cache  = "#{BOT_ROOT}/tmp/twitter_echo_cache.#{BOT_ENVIRONMENT}.txt"
    @feed   = Bot.instance.config['twitter_feed']

    # make the dir for the cache file
    FileUtils.mkdir_p(File.join(BOT_ROOT, 'tmp'))
    # and touch the file
    FileUtils.touch(@cache)
  end
  
  def echo_tweets
    posts.reverse.each do |post|
      speak("#{coder.decode(post.from)}: #{coder.decode(post.text)} #{post.link}")
    end
    save_latest
  end
  
  protected
  
  def raw_feed
    @doc ||= Hpricot(rio(@feed) > (string ||= ""))
  end
  
  def entries
    (raw_feed/'entry').map { |e| OpenStruct.new(:from => (e/'name').inner_html, :text => (e/'title').inner_html, :link => (e/'link').first['href'], :date => Time.parse((e/'published').inner_html)) }
  end
  
  def latest_tweet
    entries.first
  end
  
  def save_latest
    archive_file.truncate
    archive_file << latest_tweet.date.to_s
  end
  
  def archive_file
    rio(@cache)
  end
  
  def archived_latest_date
    archive_file >> (string ||= "")
    Time.parse(string)
  end
  
  def posts
    entries.reject { |e| e.date.to_i <= archived_latest_date.to_i }
  end
  
  def coder
    HTMLEntities.new
  end
end

