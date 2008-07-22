require 'hpricot'
require 'open-uri'

class Weather < PluginBase
  respond_to_command 'weather', :weather
  
  def weather(msg)
    doc = Hpricot(open("http://weather.yahooapis.com/forecastrss?p=ASXX0023&u=c"))
    paste(doc.search('description'))
  end
end