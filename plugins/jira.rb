require 'open-uri'
require 'hpricot'
require 'tempfile'

class Jira < CampfireBot::Plugin
  
  at_interval 3.minutes, :fetch_jira
  on_command 'checkjira', :check_jira
  
  
  def initialize
    puts "#{Time.now} | #{bot.config['room']} | JIRA Plugin | initializing... "
    @data_file  = File.join(BOT_ROOT, 'tmp', "jira-#{BOT_ENVIRONMENT}-#{bot.config['room']}.yml")
    @cached_ids = YAML::load(File.read(@data_file)) rescue {}
    @last_checked ||= 10.minutes.ago
  end
  

  def fetch_jira(msg)
    
    issuecount = 0
    @cached_ids ||= {}
    old_cache = Marshal::load(Marshal.dump(@cached_ids)) # since ruby doesn't have deep copy
    puts "#{Time.now} | #{msg[:room].name} | JIRA Plugin | checking jira for new issues..."

    begin

      xmldata = open(bot.config['jira_url']).read
      doc = REXML::Document.new(xmldata)

      
      tix = []
      doc.elements.each('rss/channel/item') do |ele|
        tix.push(ele)
      end
      
      # need to reverse these elements so we get the oldest one first
      tix.reverse.each do |ele|
        id = ele.elements['key'].text
        id, key = split_spacekey_and_id(id)
       
        if !old_cache.key?(key) or old_cache[key] < id

          # puts "#{Time.now} | #{msg[:room].name} | JIRA Plugin | ticket #{ele.elements['key'].text} is new, updating cache and speaking"
          @cached_ids[key] = id if !@cached_ids.key?(id) or @cached_ids[key] < id

          issuecount += 1
          link = ele.elements['link'].text
          title = ele.elements['title'].text
          reporter = ele.elements['reporter'].text
          type = ele.elements['type'].text
          priority = ele.elements['priority'].text
          msg.speak("#{type} - #{title} - #{link} - reported by #{reporter} - #{priority}")
          puts "#{Time.now} | #{msg[:room].name} | JIRA Plugin | #{type} - #{title} - #{link} - reported by #{reporter} - #{priority}"
        end
      end
    
    rescue Exception => e
      puts "#{Time.now} | #{msg[:room].name} | JIRA Plugin | error connecting to jira: #{e.message}"
    end
    
    File.open(@data_file, 'w') do |out|
      YAML.dump(@cached_ids, out)
    end

    @last_checked = Time.now
    puts "#{Time.now} | #{msg[:room].name} | JIRA Plugin | no new issues." if issuecount == 0
    issuecount
  
  end
  
  def check_jira(msg)
    lastlast = time_ago_in_words(@last_checked)
    count = fetch_jira(msg)
    msg.speak "no new issues since I last checked #{lastlast} ago" if count == 0
  end
  
  protected
  
  def split_spacekey_and_id(key)
    spacekey = key.scan(/^([A-Z]+)/).to_s
    id = key.scan(/([0-9]+)$/)[0].to_s.to_i
    return id, spacekey
  end
  
  def time_ago_in_words(from_time, include_seconds = false)
    distance_of_time_in_words(from_time, Time.now, include_seconds)
  end
  
  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round

    case distance_in_minutes
      when 0..1
        return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
        case distance_in_seconds
          when 0..4   then 'less than 5 seconds'
          when 5..9   then 'less than 10 seconds'
          when 10..19 then 'less than 20 seconds'
          when 20..39 then 'half a minute'
          when 40..59 then 'less than a minute'
          else             '1 minute'
        end

        when 2..44           then "#{distance_in_minutes} minutes"
        when 45..89          then 'about 1 hour'
        when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
        when 1440..2879      then '1 day'
        when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
        when 43200..86399    then 'about 1 month'
        when 86400..525599   then "#{(distance_in_minutes / 43200).round} months"
        when 525600..1051199 then 'about 1 year'
        else                      "over #{(distance_in_minutes / 525600).round} years"
    end
  end
  
end