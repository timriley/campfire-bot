require 'cgi'
require 'yaml'

# Lookup bug titles and URLs when their number is mentioned or on command.
#
# You'll probably want to at least configure bugzilla_bug_url with the
# URL to your bug tracking tool.  Put a '%s' where the bug ID should be
# inserted.
#
# Several other options are available, including the interval in which
# to avoid volunteering the same information, and whether to show the
# url with the title.
#
# The external program "wget" is used to download web pages.
#
# While is designed to work with Bugzilla, it also works fine with:
# * Debian bug tracking system
# * KDE Bug tracking system
# * Trac - if you don't mind calling your tickets bugs
# * Redmine - if you don't mind calling your issues bugs
class Bugzilla < CampfireBot::Plugin
  MENTION_REGEXP = /bugs?:?\s+
                    (?:[0-9]{3,6})
                    (?:(?:,\s*|,?\sand\s|,?\sor\s|\s+)
                     (?:[0-9]{3,6})
                     )*/ix
  on_message MENTION_REGEXP, :describe_mention
  on_command 'bug', :describe_command

  def self.config_var(name, default)
    attr_reader name
    @@config_defaults ||= {}
    @@config_defaults[name] = default
  end

  config_var :data_file, File.join(BOT_ROOT, 'tmp', 'bugzilla.yml')
  config_var :min_period, 30.minutes
  config_var :debug_enabled, false
  config_var :bug_url, "https://bugzilla/show_bug.cgi?id=%s"
  config_var :link_enabled, true

  attr_reader :bug_timestamps

  def initialize()
    @@config_defaults.each_pair { |name, default|
      instance_variable_set("@#{name.to_s}",
                            bot.config["bugzilla_#{name.to_s}"] || default)
    }
    @bug_timestamps = YAML::load(File.read(@data_file)) rescue {}
    if link_enabled
      require 'shorturl'
    end
  end

  def debug(spew)
    $stderr.puts "#{self.class.name}: #{spew}" if debug_enabled
  end

  def describe_mention(msg)
    debug "heard a mention"
    match = msg[:message].match(MENTION_REGEXP)
    describe_bugs msg, match.to_s, true
  end

  def describe_command(msg)
    debug "received a command"
    debug "msg[:message] = #{msg[:message].inspect}"
    describe_bugs msg, msg[:message], false
  end

  protected

  def describe_bugs(msg, text, check_timestamp)
    summaries = text.to_s.scan(/[0-9]{3,6}/).collect { |bug|
      debug "mentioned bug #{bug}"
      now = Time.new
      last_spoke = (bug_timestamps[msg[:room].name] ||= {})[bug]
      if check_timestamp && !last_spoke.nil? && last_spoke > now - min_period
        debug "keeping quiet, last spoke at #{last_spoke}"
        nil
      else
        debug "fetching title for #{bug}"
        url = sprintf(bug_url, bug)
        # relies on .netrc for password
        cmd = "wget --no-check-certificate -q -O - #{url}"
        html = `#{cmd}`
        if !m = html.match("<title>([^<]+)</title>")
          raise "no title for bug #{bug}!"
        end
        debug "fetched."
        title = CGI.unescapeHTML(m[1])
        title += " (#{ShortURL.shorten(url)})" if link_enabled
        bug_timestamps[msg[:room].name][bug] = now
        title
      end
    }.reject { |s| s.nil? }
    if !summaries.empty?
      n = bug_timestamps.inject(0) { |sum, pair| sum + pair[1].size }
      debug "Rewriting #{n} timestamps"
      File.open(data_file, 'w') do |out|
        YAML.dump(bug_timestamps, out)
      end
      # Speak the summaries all at once so they're more readable and
      # not interleaved with someone else's speach
      summaries.each { |s|
        debug "sending response: #{s}"
        msg.speak s
      }
    else
      debug "nothing to say."
    end
  end
end
