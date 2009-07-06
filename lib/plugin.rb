module CampfireBot  
  class Plugin
    @registered_plugins   = {}
    
    @registered_commands  = []
    @registered_messages  = []
    @registered_speakers  = []
    @registered_intervals = []
    @registered_times     = []
    
    class << self
      attr_reader :registered_plugins,
                  :registered_commands,
                  :registered_messages,
                  :registered_speakers,
                  :registered_intervals,
                  :registered_times

      # Registering plugins

      def inherited(child)
        Plugin.registered_plugins[child.to_s] = child
      end

      # Event handlers

      def on_command(command, *methods)
        methods.each do |method|
          Plugin.registered_commands << Event::Command.new(command, self.to_s, method)
        end
      end

      def on_message(regexp, *methods)
        methods.each do |method|
          Plugin.registered_messages << Event::Message.new(regexp, self.to_s, method)
        end
      end

      def on_speaker(speaker, *methods)
        methods.each do |method|
          Plugin.registered_speakers << Event::Speaker.new(speaker, self.to_s, method)
        end
      end

      def at_interval(interval, *methods)
        methods.each do |method|
          Plugin.registered_intervals << Event::Interval.new(interval, self.to_s, method)
        end
      end

      def at_time(timestamp, *methods)
        methods.each do |method|
          Plugin.registered_times << Event::Time.new(timestamp, self.to_s, method)
        end
      end

      # Declare a plugin configuration parameter with its default value
      def config_var(name, default)
        attr_reader name
        @@config_defaults ||= {}
        @@config_defaults[self.name] ||= {}
        @@config_defaults[self.name][name] = default
      end
    end
    def initialize
      # initialize attr_readers setup with config_var
      config_prefix = self.class.to_s.underscore
      (@@config_defaults[self.class.name] || {}).each_pair { |name, default|
        instance_variable_set("@#{name.to_s}",
                              bot.config["#{config_prefix}_#{name.to_s}"] ||
                                default)
      }
    end
  end
end
