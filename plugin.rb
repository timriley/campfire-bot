class MessageHandler
  attr_reader :kind, :matcher, :plugin, :method
  
  def initialize(kind, matcher, plugin, method)
    @kind     = kind
    @matcher  = matcher
    @plugin   = plugin
    @method   = method
  end
  
  def match?(msg)
    case @kind
    when :command
      msg[:message][0..0] == '!' && msg[:message].gsub(/^!/, '').split(' ').first == @matcher
    when :speaker
      msg[:person] == @matcher
    when :message
      msg[:message] =~ @matcher
    else
      false
    end
  end
  
  def run(msg, force = false)
    PluginBase.registered_plugins[@plugin].send(@method, msg) if force || match?(msg)
  end  
end

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

class PluginBase
  @registered_plugins   = {}
  
  @registered_commands  = []
  @registered_messages  = []
  @registered_speakers  = []
      
  class << self
    extend PluginSugar
    def_field :author, :version
    
    attr_reader :registered_plugins,
                :registered_commands,
                :registered_messages,
                :registered_speakers
  end

  # Registering plugins
  
  def self.inherited(child)
    PluginBase.registered_plugins[child.to_s] = child
  end

  # Event handlers
  
  def self.respond_to_command(command, *methods)
    methods.each do |method|
      PluginBase.registered_commands << MessageHandler.new(:command, command, self.to_s, method)
    end
  end
  
  def self.respond_to_message(regexp, *methods)
    methods.each do |method|
      PluginBase.registered_messages << MessageHandler.new(:message, regexp, self.to_s, method)
    end
  end
  
  def self.respond_to_speaker(speaker, *methods)
    methods.each do |method|
      PluginBase.registered_speakers << MessageHandler.new(:speaker, speaker, self.to_s, method)
    end
  end
  
  # TODO
  
  def self.at_interval(seconds, &block)
    
  end
  
  def self.at_time(timestamp, &block)
    
  end

  # Shortcuts to access the room
  
  def speak(words)
    Bot.instance.room.speak(words)
  end
  
  def paste(words)
    Bot.instance.room.paste(words)
  end
end