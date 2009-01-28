require 'hpricot'

class Basecamp < CampfireBot::Plugin
  on_command 'writeboard', :writeboard
  
  def initialize
    # TODO find a better temp file name
    @cookie_jar = BOT_ROOT + '/tmp/basecamp-cookies.txt'
    @writeboard = bot.config['basecamp_writeboard_url']
    @domain     = @writeboard.split(/\/+/)[1]
    @username   = bot.config['basecamp_username']
    @password   = bot.config['basecamp_password']
    @ssl        = !!bot.config['basecamp_use_ssl']
  end
  
  def writeboard(msg)
    msg.paste get_contents
  end
  
  private
  
  # TODO escape stuff here. output = `#{Escape.shell_command(['figlet', '--', m[:message]])}`
  def get_contents
    # Prime the cookie jar: log in.
    basecamp_login      = `curl -c #{@cookie_jar} -b #{@cookie_jar} -d "user_name=#{@username}&password=#{@password}" -L http#{'s' if @ssl}://#{@domain}/login/authenticate`
    
    # Fetch the contents of the writeboard redirect page
    writeboard_redir    = `curl -c #{@cookie_jar} -b #{@cookie_jar} -L #{@writeboard}`
    
    # Simulate the javascripted login to the writeboard site
    redir_form          = Hpricot(writeboard_redir).search('form').first
    writeboard_url      = redir_form['action'].gsub(/\/login$/, '')
    writeboard_author   = bot.config['nickname']
    writeboard_password = redir_form.search("input[@name='password']").first['value']
    
    writeboard_login    = `curl -c #{@cookie_jar} -b #{@cookie_jar} -d "author_name=#{writeboard_author}&password=#{writeboard_password}" -L #{redir_form['action']}`
    
    # Now we can get the contents of the writeboard's page, which contains a link to the text export
    writeboard_page     = Hpricot(`curl -c #{@cookie_jar} -b #{@cookie_jar} -L #{writeboard_url}`)
    
    export_link         = 'http://123.writeboard.com' + writeboard_page.search("a[@href*='?format=txt']").first['href']
    
    # Finally, grab the text export
    writeboard_text     = `curl -c #{@cookie_jar} -b #{@cookie_jar} #{export_link}`
    
    return writeboard_text
  end
end