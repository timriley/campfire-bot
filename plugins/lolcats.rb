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

class LolCats < PluginBase
  on_command 'lolcat', :lolcats
  
  def lolcats(msg)
    # Scrape random lolcat
    lolcat = (Hpricot(open('http://icanhascheezburger.com/?random#top'))/'div.snap_preview img').first
    
    # Now download it
    file = Tempfile.new("lolcat-#{lolcat['src'].split('/').last}")
    file.write(open(lolcat['src']).read)
    file.flush
    
    # Upload it
    upload(file.path)
    
    # And remove the tempfile
    file.close!
  rescue => e
    speak e
  end
end