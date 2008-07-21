Plugin.define 'fun' do
  author 'Tim R.'
  version '1.0.0'
        
  respond_to_command('test') do |m|
    speak(@test)
  end
  
  respond_to_command('say') do |m|
    speak(m[:message].gsub(/^!\w+/, ''))
  end
  
  # @last_agreed = 20.minutes.ago
  
  respond_to_speaker('Tim R.') do |m|
    @last_agreed ||= 20.minutes.ago
    puts "AGREED AT #{@last_agreed.inspect}"
    speak('I agree with Tim.') unless @last_agreed > 15.minutes.ago
    @last_agreed ||= Time.now
  end
end