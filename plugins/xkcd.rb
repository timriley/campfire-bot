require 'open-uri'
require 'hpricot'
require 'tempfile'

# From http://blog.nicksieger.com/articles/2008/03/14/monkey-patching-is-part-of-the-diy-culture
Tempfile.class_eval do
  # Make tempfiles use the extension of the basename. This is important for images.
  def make_tmpname(basename, n)
    ext = nil
    sprintf("%s%d-%d%s", basename.to_s.gsub(/\.\w+$/) { |s| ext = s; '' }, $$, n, ext)
  end
end

class Xkcd < CampfireBot::Plugin
  BASE_URL = 'http://xkcd.com/'
  
  on_command 'xkcd', :xkcd
  
  def xkcd(msg)    
    # Get the comic info
    comic = case msg[:message].split(/\s+/)[0]
    when 'latest'
      fetch_latest
    when 'random'
      fetch_random
    when /d+/
      fetch_comic(msg[:message].split(/\s+/)[0])
    else
      fetch_random
    end
    
    # Now download it
    file = Tempfile.new("xkcd-#{comic['src'].split('/').last}")
    file.write(open(comic['src']).read)
    file.flush
    
    puts file.path 
    
    # Upload it
    msg.upload(file.path)
    msg.speak(comic['title'])
    
    # And remove the tempfile
    file.close!
  end
  
  private
  
  def fetch_latest
    fetch_comic
  end
  
  def fetch_random
    # Fetch the latest page and then find the link to the previous comic.
    # This will give us a number to work with (that of the penultimate strip).
    fetch_comic(rand((Hpricot(open(BASE_URL))/'//*[@accesskey="p"]').first['href'].gsub(/\D/, '').to_i + 1))
  end
  
  def fetch_comic(id = nil)
    # Rely on the comic being the last image on the page with a title attribute
    (Hpricot(open("#{BASE_URL}#{id.to_s + '/' if id}"))/'img[@title]').last
  end
end