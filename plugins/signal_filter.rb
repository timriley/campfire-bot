class SignalFilter < CampfireBot::Plugin
  on_message /^\[.*?\]/i, :echo_signal
  
  def echo_signal(msg)
    unless msg[:room] == bot.config['signal_target_room']
      bot.rooms[bot.config['signal_target_room']].speak("#{msg[:person]} #{msg[:message]}")
    end
  end
end