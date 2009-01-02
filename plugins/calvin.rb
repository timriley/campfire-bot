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

class Calvin < CampfireBot::Plugin
  BASE_URL    = 'http://www.marcellosendos.ch/comics/ch/'
  START_DATE  = Date.parse('1984-08-14')
  END_DATE    = Date.parse('1995-12-31') # A sad day
  
  on_command 'calvin', :calvin
  
  def calvin(msg)    
    comic = case msg[:message].split(/\s+/)[0]
    when 'random'
      fetch_random
    when /d+/
      fetch_comic(msg[:message].split(/\s+/)[0])
    else
      fetch_random
    end
    
    # Now download it
    file = Tempfile.new("calvin-#{comic.split('/').last}")
    file.write(open(comic).read)
    file.flush
    
    # Upload it
    msg.upload(file.path)
    
    # And remove the tempfile
    file.close!
  end
  
  private
  
  def fetch_random
    fetch_comic(rand(number_of_comics))
  end
  
  def fetch_comic(id = nil)
    date = id_to_date(id)
    "#{BASE_URL}#{date.strftime('%Y')}/#{date.strftime('%m')}/#{date.strftime('%Y%m%d')}.gif"
  end
  
  def id_to_date(id)
    (START_DATE + id.days).to_date
  end
  
  def number_of_comics
    (END_DATE - START_DATE).to_i
  end
end