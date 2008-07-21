# http://eigenclass.org/hiki.rb?ruby+plugins
module PluginSugar
  def def_field(*names)
    class_eval do 
      names.each do |name|
        define_method(name) do |*args| 
          case args.size
            when 0: instance_variable_get("@#{name}")
            else    instance_variable_set("@#{name}", *args)
          end
        end
      end
    end
  end
end

class Plugin
  @registered_plugins   = {}
  @registered_commands  = []
  @registered_messages  = []
  @registered_speakers  = []
    
  class << self
    attr_reader :registered_plugins,
                :registered_commands,
                :registered_messages,
                :registered_speakers
    private :new
  end

  # Building plugins

  def self.define(name, &block)
    plugin = new
    plugin.instance_eval(&block)
    Plugin.registered_plugins[name] = plugin
  end
  
  # Event handlers
  
  def respond_to_command(command, &block)
    Plugin.registered_commands << [command, block]
  end
  
  def respond_to_message(regexp, &block)
    Plugin.registered_messages << [regexp, block]
  end
  
  def respond_to_speaker(speaker, &block)
    Plugin.registered_speakers << [speaker, block]
  end
  
  # TODO
  
  def at_interval(seconds, &block)
    
  end
  
  def at_time(timestamp, &block)
    
  end

  # Shortcuts to access the room
  
  def speak(words)
    Bot.instance.room.speak(words)
  end
  
  def paste(words)
    Bot.instance.room.paste(words)
  end
  
  extend PluginSugar
  def_field :author, :version
end