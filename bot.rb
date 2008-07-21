#!/usr/bin/env ruby

require 'rubygems'
require 'tinder'
require 'icalendar'
require 'net/http'
require 'uri'
require 'activesupport'
require 'yaml'

class Bot
  # this is necessary so the room and campfire objects can be accessed by plugins.
  include Singleton
  
  attr_reader :campfire, :room
  
  def initialize
    # Load plugins
    Dir["#{File.dirname(__FILE__)}/plugins/*.rb"].each{|x| load x }
  end
  
  def connect(environment)
    @config   = YAML::load(File.read(File.join(File.dirname(__FILE__), 'config.yml')))[environment]
    @campfire = Tinder::Campfire.new(@config['site'])
    @campfire.login(@config['username'], @config['password'])
    @room = @campfire.find_room_by_name(@config['room'])
    @room.join
  end
  
  def run(interval = 5)
    catch(:stop_listening) do
      trap('INT') { throw :stop_listening }
      loop do
        ping
        @room.messages.each {|msg| handle_message(msg) }
        sleep interval
      end
    end
  end
  
  private
  
  def handle_message(msg)
    # Look for commands
    if m[:message][0..0] == '!'
      Plugin.registered_commands.each do |handler|
        handler[1].call(msg) if handler[0] == m[:message].gsub(/^!/, '').split(' ').first
      end
    end
    
    # Look for speakers
    Plugin.registered_speakers.each do |handler|
      handler[1].call(msg) if handler[0] == m[:person]
    end
  end
end

b = Bot.instance
b.connect('development')
b.run