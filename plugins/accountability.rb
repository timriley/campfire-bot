class Accountability < CampfireBot::Plugin
  on_message /^\[INDAY/i, :save_speaker
  at_interval 5.minutes, :keep_them_honest
  
  def initialize
    @informative_people = []
    @room = bot.rooms[bot.config['accountability_room']]
  end
  
  def save_speaker(msg)
    if msg[:room] == bot.config['accountability_room']
      @informative_people << msg[:person] unless @informative_people.include?(msg[:person])
    end
  end
  
  def keep_them_honest(msg)
    now = Time.now
    
    # Only do this once a day, sometime between 11:00 and 11:05.
    if (Time.mktime(now.year, now.month, now.day, 11, 0)..Time.mktime(now.year, now.month, now.day, 11, 5).include?(now)
      (@room.users - @informative_people).each do |person|
        @room.speak("#{person}: We haven't seen your INDAY today. So what's the plan?")
      end
    end
  end
end