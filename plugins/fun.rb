Plugin.define 'fun' do
  author 'Tim R.'
  version '1.0.0'
  
  respond_to_command('say') do |m|
    speak(m[:message].gsub(/^!\w+/, ''))
  end
  
  respond_to_speaker('Tim R.') do |m|
    speak('I agree with Tim.')
  end
end