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

class Dilbert < CampfireBot::Plugin
  BASE_URL   = 'http://dilbert.com/'
  START_DATE = Date.parse('1996-01-01')
  
  on_command 'dilbert', :dilbert
  
  def dilbert(msg)
    comic = case msg[:message].split(/\s+/)[0]
    when 'latest'
      fetch_latest
    when 'random'
      fetch_random
    when /d+/
      fetch_comic(msg[:message].split(/\s+/)[1])
    else
      fetch_random
    end
    
    # Now download it
    file = Tempfile.new("dilbert-#{comic['src'].split('/').last}")
    file.write(open("#{BASE_URL}#{comic['src']}").read)
    file.flush
    
    # Upload it
    msg.upload(file.path)
    
    # And remove the tempfile
    file.close!
  end
  
  private
  
  def fetch_latest
    fetch_comic
  end
  
  def fetch_random
    fetch_comic(rand(number_of_comics))
  end
  
  def fetch_comic(id = nil)
    # Rely on the comic being the last image on the page not nested
    (Hpricot(open("#{BASE_URL}fast#{'/' + id_to_date(id) + '/' if id}"))/'//img').last
  end
  
  def id_to_date(id)
    (START_DATE + id.days).to_date.to_s(:db)
  end
  
  def number_of_comics
    (Date.today - START_DATE).to_i
  end
  
end