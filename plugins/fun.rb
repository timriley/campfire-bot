class FunPlugin < PluginBase
  author 'Tim R.'
  version '1.0.0'
  
  respond_to_command  'say',      :say
  respond_to_speaker  'Tim R.',   :agree_with_tim
  respond_to_message  /hidder/i,  :hidder
  # at_interval         30.seconds, :test
  
  def initialize
    @last_agreed = 20.minutes.ago
  end
  
  def say(m)
    speak(m[:message].gsub(/^!\w+/, ''))
  end
  
  def hidder(m)
    speak('*hidders*')
  end
  
  def agree_with_tim(m)
    speak('I agree with Tim.') unless @last_agreed > 15.minutes.ago
    @last_agreed = Time.now
  end
  
  def test
    speak('undo it!')
  end
end