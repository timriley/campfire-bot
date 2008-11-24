# External Libs
require 'rubygems'
require 'activesupport'
require 'yaml'

# Local Libs
require "#{BOT_ROOT}/lib/event"
require "#{BOT_ROOT}/lib/plugin"

# This requires my fork of tinder for the time being
# gem sources -a http://gems.github.com
# sudo gem install timriley-tinder
require 'tinder'

module CampfireBot
  class Bot
    # this is necessary so the room and campfire objects can be accessed by plugins.
    include Singleton

    # FIXME - these will be unaccessible if disconnected. handle this.
    attr_reader :campfire, :room, :config
  
    def initialize
      @config = YAML::load(File.read("#{BOT_ROOT}/config.yml"))[BOT_ENVIRONMENT]
    end
  
    def connect
      load_plugins
    
      if @config['guesturl']
        baseurl, guest_token = @config['guesturl'].split(/.com\//)
        @campfire = Tinder::Campfire.new(@config['site'], :guesturl => @config['guesturl'], :ssl => !!@config['ssl'])
        roomid    = @campfire.guestlogin(@config['guesturl'], @config['nickname'])
        @room     = Tinder::Room.new(@campfire, roomid, @config['room'])
      else
        @campfire = Tinder::Campfire.new(@config['site'], :ssl => !!@config['use_ssl'])
        @campfire.login(@config['username'], @config['password'])
        @room = @campfire.find_room_by_name(@config['room'])
      end
      
      @room.join
      puts "Ready."
    end
  
    def run(interval = 5)
      catch(:stop_listening) do
        trap('INT') { throw :stop_listening }
        loop do
          @room.ping
          @room.listen.each { |msg| handle_message(msg) }
        
          # Here's how I want it to look
          # @room.listen.each { |m| EventHandler.handle_message(m) }
          # EventHanlder.handle_time(optional_arg = Time.now)
        
          # Run time-oriented events
          Plugin.registered_intervals.each        { |handler| handler.run }
          Plugin.registered_times.each_with_index { |handler, index| Plugin.registered_times.delete_at(index) if handler.run }
        
          sleep interval
        end
      end
    end
  
    private
  
    def load_plugins
      Dir["#{BOT_ROOT}/plugins/*.rb"].each{|x| load x }
      
      # And instantiate them
      Plugin.registered_plugins.each_pair do |name, klass|
        Plugin.registered_plugins[name] = klass.new
      end
    end
  
    def handle_message(msg)
      puts
      puts msg.inspect
    
      Plugin.registered_commands.each { |handler| handler.run(msg) }
      Plugin.registered_speakers.each { |handler| handler.run(msg) }
      Plugin.registered_messages.each { |handler| handler.run(msg) }
    end
  end
end

def bot
  CampfireBot::Bot.instance
end