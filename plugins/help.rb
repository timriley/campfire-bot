# Rudimentary help system. Worth exploring further, though I am not sure how much access to the
# rest of the sytem plugins should be allowed. Should they only be allowed to operate in their own
# sandbox, or reach into the list of registered plugins like this one does?

class Help < CampfireBot::Plugin
  on_command 'help', :help
    
  def help(msg)
    commands = PluginBase.registered_commands.map { |command| command.matcher.to_s + " " }
 
    speak("To address me, type \"#{Bot.instance.config['nickname']},\" and a command. \n
    Available commands: #{commands}")
  end  
end
