require 'spec'
require 'rubygems'
require 'xmlsimple'

BOT_ROOT        = File.join(File.dirname(__FILE__), '..')
BOT_ENVIRONMENT = 'development'

require File.join(File.dirname(__FILE__), '../lib/bot.rb')
bot = CampfireBot::Bot.instance
require "#{BOT_ROOT}/plugins/jira.rb"


class SpecMessage < CampfireBot::Message
  attr_reader :response
  
  #overwrite message.speak method so that we can expose the output
  def speak(msg)
    puts "specmessage.speak(#{msg})"
    @response = msg
  end
  
end 

class SpecJira < CampfireBot::Plugin::Jira
  attr_accessor :cached_ids, :last_checked
end



describe "checking jira and" do

  
  # send a message to the room and return the response
  def sendmsg(msg)
    # puts "sendmsg(#{msg})"
    @message[:message] = msg
    @message[:room] = mock('room', :name => 'test')
    bot.send(:handle_message, @message)
    # puts "sendmsg returns #{@message.response}"
    @message.response
  end

  # instantiate the bot and the plugin fresh

  def setup
    bot = CampfireBot::Bot.instance
    bot.stub!(:config).and_return({'nickname' => 'Bot', 'jira_url' => 'foo'})
    @jira = SpecJira.new()
    CampfireBot::Plugin.registered_plugins['Jira'] = @jira
    @jira.cached_ids = {}
    @jira.last_checked = 15.minutes.ago
    @message = nil
  end

  def jira_response(ticketarray)
    
    jira_hash = {'rss' => {'channel' => [] }}
    
    ticketarray.each do |ticket|
      ticket.merge!({'description' => 'foo',
     'link' => "http://oz/jira/browse/#{ticket['key']}",
     'title' => 'foo',
     'reporter' => 'foo',
     'priority' => 'Critical',
     'type' => 'Bug'})
     
     jira_hash['rss']['channel'] << {'item' => ticket }
    end
    
    
    @message = SpecMessage.new(:person => 'Josh', :room => mock('room', :name => 'test'))

    
    
    
    xmldata = XmlSimple.xml_out(jira_hash, {'NoAttr' => true, 'RootName' => nil})
    
    @jira.stub!(:open).and_return(mock('foo', :read => xmldata))
    
    @jira.fetch_jira(@message)
  end

  describe "seeing a ticket higher than the last stored id" do

    before(:all) do
      setup 
      jira_response([{
        'key' => 'PIM-123', 
        'description' => 'foo',
        'link' => 'http://oz/jira/browse/PIM-123',
        'title' => 'foo',
        'reporter' => 'foo',
        'priority' => 'Critical',
        'type' => 'Bug',
        'updated' => 5.minutes.ago.to_s
        }])
      
      @jira.last_checked = 5.minutes.ago
      jira_response([{
        'key' => 'PIM-124', 
        'description' => 'foo',
        'link' => 'http://oz/jira/browse/PIM-124',
        'title' => 'foo',
        'reporter' => 'foo',
        'priority' => 'Critical',
        'type' => 'Bug',
        'updated' => 3.minutes.ago.to_s
        }])
    end

    it "should update the cached highest id" do
      @jira.cached_ids['PIM'].should eql(124)
    end
  
    it "should speak the info of the ticket" do
      @message.response.should match(/PIM-124/)
    end
    

  end

  describe "seeing a ticket we've already seen" do

    before(:all) do
      setup 
       jira_response([{
        'key' => 'PIM-123', 
      
        'updated' => Time.now().to_s
        }])
        
      jira_response([{
        'key' => 'PIM-123', 
        'description' => 'foo',
        'link' => 'http://oz/jira/browse/PIM-123',
        'title' => 'foo',
        'reporter' => 'foo',
        'priority' => 'Critical',
        'type' => 'Bug',
        'updated' => Time.now().to_s
        }])
    end

    it "should be quiet" do
      @message.response.should be(nil)
    end
      
    it "should not change the list of cached ids" do
      @jira.cached_ids.size.should eql(1)
    end


  end
    
  describe "seeing a ticket whose ID is lower than the highest seen id" do
    before(:all) do
      setup 
      jira_response([{
        'key' => 'PIM-123', 
        'updated' => 5.minutes.ago.to_s
        }])
      
      @jira.last_checked = 3.minutes.ago 

      jira_response([{
       'key' => 'PIM-120', 
       'updated' => Time.now().to_s
      }])
      
    end
    
    it "should be quiet" do
      @message.response.should be(nil)
    end
    
  end
  
  describe "seeing a space we've never seen before" do
     before(:all) do
        setup 
        jira_response([{
          'key' => 'PIM-123', 
          'updated' => 5.minutes.ago.to_s
          }])

        @jira.last_checked = 5.minutes.ago
        jira_response([{
          'key' => 'FOO-124', 
          'updated' => 3.minutes.ago.to_s
          }])
      end
      
      it "should update the cached highest id" do
        @jira.cached_ids['FOO'].should eql(124)
      end

      it "should speak the info of the ticket" do
        @message.response.should match(/FOO-124/)
      end
  end
  
  describe "getting a bunch of tickets in one go" do
    before(:all) do
      setup 
    end
    
    it "with all new" do
      @jira.cached_ids = {}
      jira_response([{
        'key' => 'PIM-1123', 
        'updated' => 5.minutes.ago.to_s
        }, 
        {'key' => 'PIM-1124', 
        'updated' => 5.minutes.ago.to_s}])  
      @jira.cached_ids['PIM'].should eql(1124)
    end

    it "with a mix of old and new" do
      @jira.cached_ids['PIM'] = 1124
      jira_response([{
        'key' => 'PIM-1125', 
        'updated' => 5.minutes.ago.to_s
        }, 
        {'key' => 'PIM-1124', 
        'updated' => 5.minutes.ago.to_s}])  
      @jira.cached_ids['PIM'].should eql(1125)
    end
    
    it "with all old" do
      @jira.cached_ids['PIM'] = 1125
      jira_response([{
        'key' => 'PIM-1123', 
        'updated' => 5.minutes.ago.to_s
        }, 
        {'key' => 'PIM-1124', 
        'updated' => 5.minutes.ago.to_s}])  
      @jira.cached_ids['PIM'].should eql(1125)
    end
    
    
    
    
  end
  
end

