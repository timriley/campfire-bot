#!/usr/bin/env ruby

require 'rubygems'
require 'tinder'
require 'icalendar'
require 'net/http'
require 'uri'
require 'activesupport'
require 'yaml'

# http://eigenclass.org/hiki.rb?ruby+plugins
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

class Plugin
  @registered_plugins   = {}
  @registered_commands  = {}
  @registered_messages  = {}
  @registered_speakers  = {}
  
  class << self
    attr_reader :registered_plugins,
                :registered_commands,
                :registered_messages,
                :registered_speakers
    private :new
  end

  def self.define(name, &block)
    plugin = new
    plugin.instance_eval(&block)
    Plugin.registered_plugins[name] = plugin
  end
  
  def listen_for_command(command, &block)
    Plugin.registered_commands[command] = block
  end

  extend PluginSugar
  def_field :author, :version
end

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
  
  def run
    @room.listen do |m|
      p m
      p m[:message]
      if m[:message][0..0] == '!'
        if response = Plugin.registered_commands[m[:message].gsub(/^!/, '').split(' ').first]
          puts "yep."
          response.call(m)
        end
      end
    end
  end
end

b = Bot.instance
b.connect('development')
b.run

# loop do
#   ical = Icalendar.parse(
#     Net::HTTP.get(URI.parse('http://homepage.mac.com/tariley/.calendars/campfire.ics'))
#   ).first
# 
#   ical.events.each do |event|
#     start_time = event.dtstart.strftime('%s').to_i
#     room.speak("Reminder: #{event.summary}") if start_time > (2.minutes.ago.to_i + 36000) && start_time < (2.minutes.from_now.to_i + 36000)
#   end
# 
#   room.ping
#   sleep 120
# end