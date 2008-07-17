# Plugin.define "foo" do
#   author "Tsukishiro M."
#   version "1.0.0"
#   
#   # stuff
#   def do_it(x)  # becomes a singleton method
#     x * 2
#   end
# end

Plugin.define 'fun' do
  author 'Tim R.'
  version '1.0.0'
  
  listen_for_command 'say' do |m|
    
  end
  
  # listen_for_message
  # listen_for_speaker
end
  