require 'open-uri'
require 'hpricot'

class Quote < CampfireBot::Plugin
  on_command 'quote', :quote
  
  def quote(msg)
    # Get our quotes from the web
    url = "http://quotes4all.net/rss/000010110/quotes.xml"
    response = ''

    begin
      # open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
      open(url, "User-Agent" => "Ruby/#{RUBY_VERSION}",
        "From" => "Campfire") { |f|
                                  
        # Save the response body
        response = f.read
      }
    
      # HPricot RDoc: http://code.whytheluckystiff.net/hpricot/
      doc = Hpricot(response)

      msg.speak((doc/"*/item/description").inner_html.gsub(/<\/?[^>]*>/,"").gsub(/\s+/," ").gsub(/\&quote;/,"'").gsub(/\&[\#|\w]\w+\;/,"").gsub(/\#39\;/,"'"))
      msg.speak((doc/"*/item/title").inner_html)

    rescue Exception => e
      msg.speak(e, "\n")
    end
  end
end