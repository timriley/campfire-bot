module CampfireBot
  module Plugin
  
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

    class Base
      @registered_plugins   = {}
      
      class << self
        extend PluginSugar
        def_field :author, :version
    
        attr_reader :registered_plugins

        # Registering plugins
  
        def inherited(child)
          PluginBase.registered_plugins[child.to_s] = child.new
        end

        # Event handlers
  
        def on_command(command, *methods)
          methods.each do |method|
            registered_handlers << CampfireBot::Event::Command.new(command, self.to_s, method)
          end
        end
  
        def on_message(regexp, *methods)
          methods.each do |method|
            registered_handlers << CampfireBot::Event::Message.new(regexp, self.to_s, method)
          end
        end
  
        def on_speaker(speaker, *methods)
          methods.each do |method|
            registered_handlers << CampfireBot::Event::Speaker.new(speaker, self.to_s, method)
          end
        end
  
        def at_interval(interval, *methods)
          methods.each do |method|
            registered_handlers << CampfireBot::Event::Interval.new(interval, self.to_s, method)
          end
        end

        def at_time(timestamp, *methods)
          methods.each do |method|
            registered_handlers << CampfireBot::Event::Time.new(timestamp, self.to_s, method)
          end
        end
      end

      protected

      # Shortcuts to access the room
  
      def speak(words)
        CampfireBot::Bot.instance.room.speak(words)
      end
  
      def paste(words)
        CampfireBot::Bot.instance.room.paste(words)
      end
  
      def upload(file_path)
        CampfireBot::Bot.instance.room.upload(file_path)
      end
    end
  end
end