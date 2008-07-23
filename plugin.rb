class EventHandler
  attr_reader :matcher, :plugin, :method
  
  def initialize(matcher, plugin, method)
    @matcher  = matcher
    @plugin   = plugin
    @method   = method
  end
    
  def run(msg, force = false)
    if force || match?(msg)
      PluginBase.registered_plugins[@plugin].send(@method, msg)
    else
      false
    end
  end
end

class CommandHandler < EventHandler
  def match?(msg)
    msg[:message][0..0] == '!' && msg[:message].gsub(/^!/, '').split(' ').first == @matcher
  end
end

class SpeakerHandler < EventHandler
  def match?(msg)
    msg[:person] == @matcher
  end
end

class MessageHandler < EventHandler
  def match?(msg)
    msg[:message] =~ @matcher
  end
end

class IntervalHandler < EventHandler
  def initialize(*args)
    @last_run = Time.now
    super(*args)
  end
  
  def match?
    @last_run < Time.now - @matcher
  end
  
  def run(force = false)
    if match?
      PluginBase.registered_plugins[@plugin].send(@method)
      @last_run = Time.now
    else
      false
    end
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
  @registered_intervals = []
      
  class << self
    extend PluginSugar
    def_field :author, :version
    
    attr_reader :registered_plugins,
                :registered_commands,
                :registered_messages,
                :registered_speakers,
                :registered_intervals
  end

  # Registering plugins
  
  def self.inherited(child)
    PluginBase.registered_plugins[child.to_s] = child
  end

  # Event handlers
  
  def self.respond_to_command(command, *methods)
    methods.each do |method|
      PluginBase.registered_commands << CommandHandler.new(command, self.to_s, method)
    end
  end
  
  def self.respond_to_message(regexp, *methods)
    methods.each do |method|
      PluginBase.registered_messages << MessageHandler.new(regexp, self.to_s, method)
    end
  end
  
  def self.respond_to_speaker(speaker, *methods)
    methods.each do |method|
      PluginBase.registered_speakers << SpeakerHandler.new(speaker, self.to_s, method)
    end
  end
  
  def self.at_interval(interval, *methods)
    methods.each do |method|
      PluginBase.registered_intervals << IntervalHandler.new(interval, self.to_s, method)
    end
  end

  # TODO - do I want to support this?
  
  def self.at_time(timestamp, *methods)
    
  end

  # Shortcuts to access the room
  
  def speak(words)
    Bot.instance.room.speak(words)
  end
  
  def paste(words)
    Bot.instance.room.paste(words)
  end
end