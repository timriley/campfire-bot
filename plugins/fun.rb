class Fun < PluginBase
  author 'Tim Riley'
  
  on_command    /say/,              :say
  on_command    /(should|can|will|shall) (i|he|she|we|they) do it\?/i, :do_or_do_not
  # on_speaker    'Tim R.',           :agree_with_tim
  # on_message    /undo it/i,         :do_it
  # on_message    /(^|\s)do it/i,     :undo_it
  # at_time       1.minute.from_now,  :do_it
  
  def initialize
    @last_agreed = 20.minutes.ago
  end
  
  def say(m)
    speak(m[:message].gsub(/^!\w+/, ''))
  end
  
  def do_it(m = nil)
    speak('Do it!')
  end
  
  def undo_it(m)
    speak('Undo it!')
  end
  
  def do_or_do_not(m)
    responses = ['Do it!', 'Don\'t do it!', 'Undo it!']
    speak(responses[rand(responses.size)])
  end
  
  def agree_with_tim(m)
    speak('I agree with Tim.') unless @last_agreed > 15.minutes.ago
    @last_agreed = Time.now
  end
end