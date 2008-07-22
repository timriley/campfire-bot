class FunPlugin < PluginBase
  author 'Tim R.'
  version '1.0.0'
  
  respond_to_command 'say',     :say
  respond_to_speaker 'Tim R.',  :agree_with_tim
  
  def initialize
    @last_agreed = 20.minutes.ago
  end
  
  def say(m)
    speak(m[:message].gsub(/^!\w+/, ''))
  end
  
  def agree_with_tim(m)
    speak('I agree with Tim.') unless @last_agreed > 15.minutes.ago
    @last_agreed = Time.now
  end
end