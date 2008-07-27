# require 'icalendar'
# require 'net/http'
# require 'uri'

# loop do
#   ical = Icalendar.parse(
#     Net::HTTP.get(URI.parse('http://homepage.mac.com/tariley/.calendars/campfire.ics'))
#   ).first
# 
#   ical.events.each do |event|
#     start_time = event.dtstart.strftime('%s').to_i
#     room.speak("Reminder: #{event.summary}") if start_time > (2.minutes.ago.to_i + 36000) && start_time < (2.minutes.from_now.to_i + 36000)
#   end
# 
#   room.ping
#   sleep 120
# end