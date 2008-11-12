require "#{BOT_ROOT}/vendor/escape/escape"

class Fun < CampfireBot::Plugin
  on_command    'figlet', :figlet
  
  def figlet(m)
    output = `#{Escape.shell_command(['figlet', '--', m[:message]])}`
    paste output
  end
end