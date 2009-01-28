require 'open-uri'
require 'hpricot'
require 'tempfile'

class Jira < CampfireBot::Plugin
  
  at_interval 3.minutes, :fetch_jira
  on_command 'checkjira', :check_jira

  def fetch_jira(msg)
    @last_checked ||= 10.minutes.ago
    issuecount = 0
    
    puts "checking jira for new issues..."
    begin
      xmldata = open(bot.config['jira_url']).read
    
      # puts xmldata

      doc = REXML::Document.new(xmldata)

      doc.elements.each('rss/channel/item') do |ele|

        timestamp = ele.elements['created'].text
        timestamp = Time.parse(timestamp) 
        # puts "timestamp: #{timestamp}"
        # puts "@last_checked #{@last_checked}"
        if timestamp > @last_checked
         issuecount += 1
         link = ele.elements['link'].text
         title = ele.elements['title'].text
         reporter = ele.elements['reporter'].text
         type = ele.elements['type'].text
         priority = ele.elements['priority'].text
         msg.speak("#{type} - #{title} - #{link} - reported by #{reporter} - #{priority}")
         puts "#{type} - #{title} - #{link} - reported by #{reporter} - #{priority}"
        end
      end

      @last_checked = Time.now
      puts "no new issues." if issuecount == 0
      issuecount
    rescue Exception => e
      puts "error connecting to jira: #{e.message}"
    end
  end
  
  def check_jira(msg)
    count = fetch_jira(msg)
    lastlast = time_ago_in_words(@last_checked)
    msg.speak "no new issues since I last checked #{lastlast} ago" if count == 0
  end
  
  protected
  
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