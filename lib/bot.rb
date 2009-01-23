# External Libs
require 'rubygems'
require 'activesupport'
require 'yaml'

# Local Libs
require "#{BOT_ROOT}/lib/message"
require "#{BOT_ROOT}/lib/event"
require "#{BOT_ROOT}/lib/plugin"

# This requires my fork of tinder for the time being
# gem sources -a http://gems.github.com
# sudo gem install timriley-tinder
# require 'tinder'
require "#{BOT_ROOT}/../tinder/lib/tinder"


module CampfireBot
  class Bot
    # this is necessary so the room and campfire objects can be accessed by plugins.
    include Singleton

    # FIXME - these will be invalid if disconnected. handle this.
    attr_reader :campfire, :rooms, :config
  
    def initialize
      @timeouts = 0
      @config   = YAML::load(File.read("#{BOT_ROOT}/config.yml"))[BOT_ENVIRONMENT]
      @rooms    = {}
    end
  
    def connect
      load_plugins
      join_rooms
    end
  
    def run(interval = 5)
      catch(:stop_listening) do
        trap('INT') { throw :stop_listening }
        loop do
          begin
            @rooms.each_pair do |room_name, room|
              room.ping
              room.listen.each { |raw_msg| handle_message(CampfireBot::Message.new(raw_msg.merge({:room => room}))) }
              # I assume if we reach here, all the network-related activity has occured successfully
              # and that we're outside of the retry-cycle
              @timeouts = 0
        
              # Here's how I want it to look
              # @room.listen.each { |m| EventHandler.handle_message(m) }
              # EventHanlder.handle_time(optional_arg = Time.now)
        
              # Run time-oriented events
              Plugin.registered_intervals.each        { |handler| handler.run }
              Plugin.registered_times.each_with_index { |handler, index| Plugin.registered_times.delete_at(index) if handler.run }
            end
        
            sleep interval
          rescue Timeout::Error => e
            if @timeouts < 5
              sleep(5 * @timeouts)
              @timeouts += 1
              retry
            else
              raise e.message
            end
          end
        end
      end
    end
    
    private
    
    def join_rooms
      if @config['guesturl']
        join_rooms_as_guest
      else
        join_rooms_as_user
      end
      puts "Ready."
    end
    
    def join_rooms_as_guest
      baseurl, guest_token  = @config['guesturl'].split(/.com\//)
      @campfire             = Tinder::Campfire.new(@config['site'], :guesturl => @config['guesturl'], :ssl => !!@config['ssl'])
      @rooms[guest_token]   = @campfire.find_room_by_guest_hash(guest_token, @config['nickname'])
      @rooms[guest_token].join
    end
    
    def join_rooms_as_user
      @campfire = Tinder::Campfire.new(@config['site'], :ssl => !!@config['use_ssl'])
      @campfire.login(@config['username'], @config['password'])
      
      @config['rooms'].each do |room_name|
        @rooms[room_name] = @campfire.find_room_by_name(room_name)
        @rooms[room_name].join
      end
    end
  
    def load_plugins
      Dir["#{BOT_ROOT}/plugins/*.rb"].each{|x| load x }
      
      # And instantiate them
      Plugin.registered_plugins.each_pair do |name, klass|
        Plugin.registered_plugins[name] = klass.new
      end
    end
  
    def handle_message(message)
      puts
      puts message.inspect
    
      Plugin.registered_commands.each { |handler| handler.run(message) }
      Plugin.registered_speakers.each { |handler| handler.run(message) }
      Plugin.registered_messages.each { |handler| handler.run(message) }
    end
  end
end

def bot
  CampfireBot::Bot.instance
end