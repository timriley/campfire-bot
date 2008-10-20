#!/usr/bin/env ruby

# External Libs
require 'rubygems'
require 'activesupport'
require 'yaml'

# Local Libs
require 'event'
require 'plugin'

# This requires my fork of tinder for the time being
require '../tinder/lib/tinder'

class Bot
  # this is necessary so the room and campfire objects can be accessed by plugins.
  include Singleton

  # FIXME - these will be unaccessible if disconnected. handle this.
  attr_reader :campfire, :room, :config
  
  def initialize
    @config = YAML::load(File.read(File.join(File.dirname(__FILE__), 'config.yml')))[BOT_ENVIRONMENT]
  end
  
  def connect
    load_plugins
    
    
    if @config['guesturl']
      baseurl, guest_token = @config['guesturl'].split(/.com\//)
      @campfire = Tinder::Campfire.new(@config['site'], :guesturl => @config['guesturl'], :ssl => @config['ssl'])
      roomid = @campfire.guestlogin(@config['guesturl'], @config['nickname'])
      @room = Tinder::Room.new(@campfire, roomid, @config['room'])
      @room.join
    else  
      @campfire = Tinder::Campfire.new(@config['site'])
      @campfire.login(@config['username'], @config['password'])
      @room = @campfire.find_room_by_name(@config['room'])
      @room.join
    end
  end
  
  def run(interval = 5)
    catch(:stop_listening) do
      trap('INT') { throw :stop_listening }
      loop do
        @room.ping
        @room.listen.each { |msg| handle_message(msg) }
        
        # Run time-oriented events
        PluginBase.registered_intervals.each  { |handler| handler.run }
        PluginBase.registered_times.each_with_index { |handler, index| PluginBase.registered_times.delete_at(index) if handler.run }
        
        sleep interval
      end
    end
  end
  
  private
  
  def load_plugins
    Dir["#{File.dirname(__FILE__)}/plugins/*.rb"].each{|x| load x }
  end
  
  def handle_message(msg)
    puts
    puts msg.inspect
    
    PluginBase.registered_commands.each { |handler| handler.run(msg) }
    PluginBase.registered_speakers.each { |handler| handler.run(msg) }
    PluginBase.registered_messages.each { |handler| handler.run(msg) }
  end
end

def bot
  Bot.instance
end

# Run this script with the environment as the only argument. eg. ./bot.rb development
BOT_ENVIRONMENT = ARGV.first

b = Bot.instance
b.connect
b.run