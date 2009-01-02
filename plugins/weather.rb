require 'yahoo-weather'

class Weather < CampfireBot::Plugin
  on_command 'weather', :weather
  
  def weather(msg)
    city = {
      'adelaide'  => 'ASXX0001',
      'brisbane'  => 'ASXX0016',
      'canberra'  => 'ASXX0023',
      'darwin'    => 'ASXX0032',
      'hobart'    => 'ASXX0057',
      'melbourne' => 'ASXX0075',
      'perth'     => 'ASXX0231',
      'sydney'    => 'ASXX0112'
    }[(msg[:message].split(' ')[1] || 'canberra').downcase]
    
    data = YahooWeather::Client.new.lookup_location(city, 'c')
    
    msg.speak("#{data.title} - #{data.condition.text}, #{data.condition.temp} deg C (high #{data.forecasts.first.high}, low #{data.forecasts.first.low})")
  end
end