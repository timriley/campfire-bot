class Help < PluginBase
  
  on_command 'help', :help
    
  def help(msg)
    
    commands = PluginBase.registered_commands.map { |command| command.matcher.to_s + " " }

    speak("To address me, type \"#{Bot.instance.config['nickname']},\" and a command. \n
    Available commands: #{commands}")
    
  end
  
  
  private
  
 
end


