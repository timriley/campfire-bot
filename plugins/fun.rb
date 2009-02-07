class Fun < CampfireBot::Plugin
  on_command    'say',              :say
  on_message    Regexp.new("^#{bot.config['nickname']},\\s+(should|can|will|shall) (i|he|she|we|they) do it\\?", Regexp::IGNORECASE), :do_or_do_not
  on_message    Regexp.new("^(good morning|morning|m0ink|hello|hi|hey|whassup|what's up|yo|hola|ola|'sup|sup)(,)*\\s*(#{bot.config['nickname']}).*$", Regexp::IGNORECASE), :greet
  on_message  /(how's it|how are|how're) (ya |you )*(going|doing|doin).*/, :howareya
  # on_speaker    'Tim R.',           :agree_with_tim
  # on_message    /undo it/i,         :do_it
  # on_message    /(^|\s)do it/i,     :undo_it
  # at_time       1.minute.from_now,  :do_it
  
  def initialize
    @last_agreed = 20.minutes.ago
  end
  
  def say(m)
    m.speak(m[:message])
  end
  
  def do_it(m = nil)
    m.speak('Do it!')
  end
  
  def undo_it(m)
    m.speak('Undo it!')
  end
  
  def do_or_do_not(m)
    responses = ['Do it!', 'Don\'t do it!', 'Undo it!']
    m.speak(responses.rand)
  end
  
  def agree_with_tim(m)
    m.speak('I agree with Tim.') unless @last_agreed > 15.minutes.ago
    @last_agreed = Time.now
  end
  
  def greet(m)
    messages = ['Howdy', 'Wassup', 'Greets', 'Hello', 'Hey there', "It's a", 'Good day']
    m.speak("#{messages.rand} #{m[:person].split(' ')[0]}")
  end
  
  def howareya(m)
    messages = ["just great", "peachy", "mas o menos", 
    	 "you know how it is", "eh, ok", "pretty good. how about you?"]
    m.speak(messages[rand(messages.size)])
  end
end