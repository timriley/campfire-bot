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
# HTMLEntities will be used for better entity (&ndash;) decoding if
# present, but is not required.
#
# Similarly, net/netrc will be used to supply HTTP Basic Auth
# credentials, but only if it's available.
#
# While is designed to work with Bugzilla, it also works fine with:
# * Debian bug tracking system
# * KDE Bug tracking system
# * Trac - if you configure to recognize "tickets" instead of "bugs"
# * Redmine - if you configure to recognize "issues" instead of "bugs"
class Bugzilla < CampfireBot::Plugin
  on_command 'bug', :describe_command
  # on_message registered below...

  config_var :data_file, File.join(BOT_ROOT, 'tmp', 'bugzilla.yml')
  config_var :min_period, 30.minutes
  config_var :debug_enabled, false
  config_var :bug_url, "https://bugzilla/show_bug.cgi?id=%s"
  config_var :link_enabled, true
  config_var :bug_id_pattern, '(?:[0-9]{3,6})'
  config_var :bug_word_pattern, 'bugs?:?\s+'
  config_var :mention_pattern,
    '%2$s%1$s(?:(?:,\s*|,?\sand\s|,?\sor\s|\s+)%1$s)*'

  attr_reader :bug_timestamps, :bug_id_regexp, :mention_regexp,
    :use_htmlentities, :use_netrc

  def initialize()
    super
    @bug_id_regexp = Regexp.new(bug_id_pattern, Regexp::IGNORECASE)
    @mention_regexp = Regexp.new(sprintf(mention_pattern,
                                         bug_id_pattern, bug_word_pattern),
                      Regexp::IGNORECASE)
    self.class.on_message mention_regexp, :describe_mention

    @bug_timestamps = YAML::load(File.read(@data_file)) rescue {}
    if link_enabled
      require 'shorturl'
    end

    # Put this in the constructor so we don't fail to find htmlentities
    # every time we fetch a bug title.
    begin
      require 'htmlentities'
      @use_htmlentities = true
    rescue LoadError
      debug "Falling back to 'cgi', install 'htmlentities' better unescaping"
      require 'cgi'
    end
    begin
      require 'net/netrc'
      @use_netrc = true
    rescue LoadError
      debug "Can't load 'net/netrc': HTTP Auth from .netrc will be unavailable"
      require 'cgi'
    end
  end

  def debug(spew)
    $stderr.puts "#{self.class.name}: #{spew}" if debug_enabled
  end

  def describe_mention(msg)
    debug "heard a mention"
    match = msg[:message].match(mention_regexp)
    describe_bugs msg, match.to_s, true
  end

  def describe_command(msg)
    debug "received a command"
    debug "msg[:message] = #{msg[:message].inspect}"
    describe_bugs msg, msg[:message], false
  end

  protected

  def describe_bugs(msg, text, check_timestamp)
    summaries = text.to_s.scan(bug_id_regexp).collect { |bug|
      debug "mentioned bug #{bug}"
      now = Time.new
      last_spoke = (bug_timestamps[msg[:room].name] ||= {})[bug]
      if check_timestamp && !last_spoke.nil? && last_spoke > now - min_period
        debug "keeping quiet, last spoke at #{last_spoke}"
        nil
      else
        debug "fetching title for #{bug}"
        url = sprintf(bug_url, bug)
        html = http_fetch_body(url)
        if !m = html.match("<title>([^<]+)</title>")
          raise "no title for bug #{bug}!"
        end
        debug "fetched."
        title = html_decode(m[1])
        title += " (#{ShortURL.shorten(url)})" if link_enabled
        bug_timestamps[msg[:room].name][bug] = now
        title
      end
    }.reject { |s| s.nil? }
    if !summaries.empty?
      expire_timestamps
      n = bug_timestamps.inject(0) { |sum, pair| sum + pair[1].size }
      debug "Writing #{n} timestamps"
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

  # Don't let the datafile or the in-memory list grow too
  # large over long periods of time.  Remove entries that are
  # well over min_period.
  def expire_timestamps
    debug "Expiring bug timestamps"
    cutoff = Time.new - (2 * min_period)
    recent = {}
    bug_timestamps.each { |room, hash|
      recent[room] = {}
      hash.each { |bug, ts|
        recent[room][bug] = ts if ts > cutoff
      }
      recent.delete(room) if recent[room].empty?
    }
    @bug_timestamps = recent
  end

  # Returns the non-HTML version of the given string using
  # htmlentities if available, or else unescapeHTML
  def html_decode(html)
    if use_htmlentities
      HTMLEntities.new.decode(html)
    else
      CGI.unescapeHTML(html)
    end
  end

  # Return the HTTPResponse
  #
  # Use SSL if necessary, and check .netrc for
  # passwords.
  def http_fetch(url)
    uri = URI.parse url
    http = Net::HTTP.new(uri.host, uri.port)

    # Unfortunately the net/http(s) API can't seem to do this for us,
    # even if we require net/https from the beginning (ruby 1.8)
    if uri.scheme == "https"
      require 'net/https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    res = http.start { |http|
      req = Net::HTTP::Get.new uri.request_uri
      cred = netrc_credentials uri.host
      req.basic_auth *cred if cred
      http.request req
    }
  end

  # Returns only the document body
  def http_fetch_body(url)
    res = http_fetch(url)
    case res
    when Net::HTTPSuccess
      res.body
    else res.error!
    end
  end

  # Returns [username, password] for the given host or nil
  def netrc_credentials(host)
    # Don't crash just b/c the gem is not installed
    return nil if !use_netrc
    obj = Net::Netrc.locate(host)
    obj ? [obj.login, obj.password] : nil
  end
end
