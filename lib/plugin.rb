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
    end
  end
end