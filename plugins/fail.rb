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

class Fail < CampfireBot::Plugin
  on_command 'fail', :fail
  
  def fail(msg)
    # Scrape random fail
    fail = (Hpricot(open('http://failblog.org/?random#top'))/'div.snap_preview img').first
    
    # Now download it
    file = Tempfile.new("fail-#{fail['src'].split('/').last}")
    file.write(open(fail['src']).read)
    file.flush
    
    # Upload it
    msg.upload(file.path)
    
    # And remove the tempfile
    file.close!
  rescue => e
    msg.speak e
  end
end