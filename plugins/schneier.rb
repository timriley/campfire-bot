require 'open-uri'
require 'hpricot'

class Schneier < PluginBase
  BASE_URL   = 'http://geekz.co.uk/schneierfacts/fact'
  
  on_command 'schneier', :schneier
  
  def schneier(msg)
    quote = case msg[:message].split(/\s+/)[1]
    when 'latest'
      fetch_quote
    when 'random'
      fetch_random
    else
      fetch_random
    end
    speak quote
  rescue => e
    speak e
  end
  
  private
  
  def fetch_random
    fetch_quote(rand(total_quotes))
  end
  
  def fetch_quote(id = nil)
    (Hpricot(open("#{BASE_URL}/#{id ? id : 'latest'}"))).search('p .fact').html
  end
  
  def total_quotes
    (Hpricot(open("#{BASE_URL}/latest"))).search('.navigation a').first.attributes['href'].split('/').reverse[0].to_i
  end
end