require 'open-uri'
require 'hpricot'

class Chuck < CampfireBot::Plugin
  on_command 'chuck', :chuck
  
  def chuck(msg)
    # Get our sayings from a Chuck Norris facts page (one of 9 to-date)
    url = "http://www.chucknorrisfacts.com/page#{rand(8)+1}.html"
    response = ''
    fact_file = Array.new

    begin
      # open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
      open(url, "User-Agent" => "Ruby/#{RUBY_VERSION}",
        "From" => "Campfire") { |f|
                                  
        # Save the response body
        response = f.read
      }
    
      # HPricot RDoc: http://code.whytheluckystiff.net/hpricot/
      doc = Hpricot(response)
    
      # Pull out all the facts and load them into an array
      (doc/"*/li").each do |fact|
         fact_file << "#{fact.inner_html}"
      end

      # Select a random entry in the array, clean the string and output it  
      msg.speak(fact_file[rand(fact_file.size)].gsub(/<\/?[^>]*>/,"").gsub(/\s+/," ").gsub(/\&quote;/,"'").gsub(/\&[\#|\w]\w+\;/,""))
    rescue Exception => e
      msg.speak(e, "\n")
    end
  end
end