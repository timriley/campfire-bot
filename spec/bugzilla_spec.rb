require 'spec'
BOT_ROOT        = File.join(File.dirname(__FILE__), '..')
BOT_ENVIRONMENT = 'test'

require File.join(File.dirname(__FILE__), '../lib/bot.rb')
bot = CampfireBot::Bot.instance
require "#{BOT_ROOT}/plugins/bugzilla.rb"

describe "Bugzilla plugin" do
  before(:each) do
    require 'shorturl'
    ShortURL.stub!(:shorten).
      with("https://bugzilla/show_bug.cgi?id=1234").
      and_return("http://rubyurl.com/xyz")
    @bot = CampfireBot::Bot.instance
    @bot.stub!(:config).and_return('nickname' => 'Bot'
                                   #,'bugzilla_debug_enabled' => true
                                   )
    @bugzilla = Bugzilla.new
    @bugzilla.stub!(:http_fetch_body).
      with("https://bugzilla/show_bug.cgi?id=1234").
      and_return(
        "<html>
           <head>
             <title>Bug 1234 - Fix widget behavior</title>
           </head>
         </html>")
    CampfireBot::Plugin.registered_plugins['Bugzilla'] = @bugzilla
    @message = CampfireBot::Message.new(:room => Tinder::Room.new(42, "Main"),
                                        :person => 'Josh')
  end

  after(:each) do
    if File.exist? @bugzilla.data_file
      File.unlink(@bugzilla.data_file)
    end
  end

  it "should respond to the command !bug" do
    @bugzilla.should_receive(:describe_command)
    @message[:message] = "!bug"
    @bot.send(:handle_message, @message)
  end

  it "should respond to !bug with a bug title" do
    @message.should_receive(:speak).
      with("Bug 1234 - Fix widget behavior (http://rubyurl.com/xyz)")
    @message[:message] = "!bug 1234"
    @bot.send(:handle_message, @message)
  end

  it "should overhear mentions of 'bug NNNN' and offer the title" do
    @message.should_receive(:speak).
      with("Bug 1234 - Fix widget behavior (http://rubyurl.com/xyz)")
    @message[:message] = "What about bug 1234?"
    @bot.send(:handle_message, @message)
  end

  it "should not repeat a bug title twice in a short time when overhearing" do
    @message.should_receive(:speak).
      with("Bug 1234 - Fix widget behavior (http://rubyurl.com/xyz)")
    @message[:message] = "What about bug 1234?"
    @bot.send(:handle_message, @message)

    @message2 = CampfireBot::Message.new(:room => Tinder::Room.new(42, "Main"),
                                         :person => 'Josh')
    @message2.should_not_receive(:speak)
    @message2[:message] = "I fixed bug 1234, too."
    @bot.send(:handle_message, @message2)
  end
end

describe "http_fetch_body method" do
  before(:each) do
  end
  # Probably this method should live elsewhere, and in that location be
  # broken down into smaller methods to facilitate testing.
  it "should return the body of an HTTP response" do
    pending
  end
  it "should raise an exception for non-success status" do
    pending
  end
  it "should use netrc credentials when possible" do
    pending
  end
  it "should support https when necessary" do
    pending
  end
end
