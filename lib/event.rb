module CampfireBot
  module Event
    
    # This is an abstract base class for all event types, not to be used directly.
    class EventHandler
      
      attr_reader :kind, :matcher, :plugin, :method
    
      def self.handles(event_type)
        @kind = event_type
      end
  
      def initialize(matcher, plugin_name, method_name)
        @matcher  = matcher
        @plugin   = plugin_name
        @method   = method_name
      end
    
      def run(msg, force = false)
        if force || match?(msg)
          Plugin.registered_plugins[@plugin].send(@method, filter_message(msg))
        else
          false
        end
      end
  
      protected
  
      def filter_message(msg)
        msg
      end
    end
    
    class Command < EventHandler
      handles :messages
  
      def match?(msg)
        (
          msg[:message][0..0] == '!' || 
          msg[:message]       =~ Regexp.new("^#{bot.config['nickname']},", Regexp::IGNORECASE)
        ) &&
        msg[:message].gsub(/^!/, '').gsub(Regexp.new("#{bot.config['nickname']}(,|:)?\\s*", Regexp::IGNORECASE), '').split(' ')[0].to_s.downcase == @matcher.downcase
        # FIXME - the above should be just done with one regexp to pull out the first non-! non-<bot name> word.
      end
  
      protected
  
      def filter_message(msg)
        msg[:message] = msg[:message].gsub(Regexp.new("^(!|#{bot.config['nickname']},)\\s*#{@matcher}\\s*", Regexp::IGNORECASE), '')
        msg
      end
    end

    class Speaker < EventHandler
      handles :messages
  
      def match?(msg)
        msg[:person] == @matcher
      end
    end

    class Message < EventHandler
      handles :messages
  
      def match?(msg)
        msg[:message] =~ @matcher
      end
    end

    class Interval < EventHandler
      handles :times
  
      def initialize(*args)
        @last_run = ::Time.now
        super(*args)
      end
  
      def match?
        @last_run < ::Time.now - @matcher
      end
  
      def run(force = false)
        if match?
          Plugin.registered_plugins[@plugin].send(@method, msg)
          @last_run = ::Time.now
        else
          false
        end
      end
    end

    class Time < EventHandler
      handles :times
  
      def initialize(*args)
        @run = false
        super(*args)
      end
  
      def match?
        @matcher <= ::Time.now && !@run
      end
  
      def run(force = false)
        if match?
          Plugin.registered_plugins[@plugin].send(@method)
          @run = true
        else
          false
        end
      end
    end
  end
end