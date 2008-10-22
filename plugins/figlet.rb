require "#{BOT_ROOT}/lib/escape/escape"

class Fun < PluginBase
  on_command    'figlet', :figlet
  
  def figlet(m)
    output = `#{Escape.shell_command(['figlet', '--', m[:message]])}`
    paste output
  end
end