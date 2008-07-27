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
    (
      msg[:message][0..0] == '!' || 
      msg[:message] =~ Regexp.new("^#{Bot.instance.config['nickname']},", Regexp::IGNORECASE)
    ) &&
    msg[:message].gsub(/^!/, '').gsub(/^#{Bot.instance.config['nickname']},\s*/i, '') =~ @matcher
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

class TimeHandler < EventHandler
  def initialize(*args)
    @run = false
    super(*args)
  end
  
  def match?
    @matcher <= Time.now && !@run
  end
  
  def run(force = false)
    if match?
      PluginBase.registered_plugins[@plugin].send(@method)
      @run = true
    else
      false
    end
  end
end