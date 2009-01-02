require 'open-uri'
require 'hpricot'

class Schneier < CampfireBot::Plugin
  BASE_URL   = 'http://geekz.co.uk/schneierfacts/'
  
  on_command 'schneier', :schneier
  
  def schneier(msg)
    quote = case msg[:message].split(/\s+/)[0]
    when 'latest'
      fetch_quote(true)
    when 'random'
      fetch_quote
    else
      fetch_quote
    end
    msg.speak quote
  rescue => e
    msg.speak e
  end
  
  private

  def fetch_quote(latest = false)
    CGI::unescapeHTML((Hpricot(open("#{BASE_URL}#{'fact/latest' if latest}"))).search('p .fact').html)
  end
end