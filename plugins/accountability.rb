class Accountability < CampfireBot::Plugin
  on_message /^\[INDAY/i, :save_speaker
  at_interval 5.minutes, :keep_them_honest
  
  def initialize
    @accountable_people = []
  end
  
  def save_speaker(msg)
    if msg[:room].name == accountability_room.name
      puts "WE'RE IN!"
      @accountable_people << strip_tags(msg[:person]) unless @accountable_people.include?(strip_tags(msg[:person]))
    end
  end
  
  def keep_them_honest(msg)
    if accountability_time?
      unaccountable_people.each do |person|
        @room.speak("#{person}: We haven't seen your INDAY today. So what's the plan?")
      end
      
      @accountable_people.clear
    end
  end
  
  private
  
  def unaccountable_people
    accountability_room.users.map { |u| strip_tags(u) } - @accountable_people - [bot.config['nickname']]
  end
  
  def accountability_room
    @room ||= bot.rooms[bot.config['accountability_room']] || bot.rooms.first
  end
  
  def accountability_time?
    # Once a day, sometime between 11:00 and 11:05.
    now = Time.now
    (Time.mktime(now.year, now.month, now.day, 11, 0)..Time.mktime(now.year, now.month, now.day, 11, 5)).include?(now)
  end
  
  def strip_tags(str)
    str.gsub(/<\/?[^>]*>/, '').strip
  end
end