require 'spec'
BOT_ROOT        = File.join(File.dirname(__FILE__), '..')
BOT_ENVIRONMENT = 'test'

require File.join(File.dirname(__FILE__), '../lib/bot.rb')
bot = CampfireBot::Bot.instance
require "#{BOT_ROOT}/plugins/beer.rb"


class SpecMessage < CampfireBot::Message
  attr_reader :response
  
  #overwrite message.speak method so that we can expose the output
  def speak(msg)
    puts "specmessage.speak(#{msg})"
    @response = msg
  end
  
end 

class SpecBeer < CampfireBot::Plugin::Beer
  attr_accessor :balances
end

# send a message to the room and return the response
def sendmsg(msg)
  puts "sendmsg(#{msg})"
  @message[:message] = msg
  bot.send(:handle_message, @message)
  puts "sendmsg returns #{@message.response}"
  @message.response
end

# instantiate the bot and the plugin fresh
def setup
  bot = CampfireBot::Bot.instance
  @beer = SpecBeer.new()
  CampfireBot::Plugin.registered_plugins['Beer'] = @beer
  @message = SpecMessage.new(:person => 'Josh')
  @beer.balances = {}
  @beer.stub!(:init).and_return(@beer.balances)
  @beer.stub!(:write)
  puts @beer.balances
end

describe "giving beer" do
  before(:each) do
    setup
    
  end
  
  it "should respond to the command !give_beer" do
    @beer.should_receive(:give_beer)
    sendmsg "!give_beer"
  end
  

  it "should decrease my balance with Foo" do
    bal = @beer.balance('Josh', 'Foo')
    p "initial bal is #{bal}"
    sendmsg '!give_beer Foo'
    @beer.balance('Josh', 'Foo').should eql(bal - 1)
  end
  
  it "should say back to me what my balance is" do
    # exp = @message.should_receive(:speak)
    # .with("Okay, you now owe Foo #{bal} beers")
    #FIXME this is brittle-- need to test for negative and zero balances
    
    # lambda {sendmsg('!give_beer harvey')}.should_not eql(nil)
    sendmsg('!give_beer bruce').should_not eql(nil)
  end
  
  it "should accept an argument of the number of beers to credit" do
    bal = @beer.balance('Josh', 'harvey') + 2
    sendmsg('!give_beer harvey 2')
    @beer.balance('Josh', 'harvey').should eql(bal)
  end
  
  describe "should have the correct reply for" do

    it "negative balances (I owe beers)" do
      # @beer.stub!(:balance).and_return(0, -1)
      sendmsg("!give_beer james").should =~ /you now owe james .* beer/
    end
    
    it "positive balances (I am owed beers)" do
      @beer.balances['joshalbert'] = 5
      sendmsg("!give_beer albert").should =~ /albert now owes you .* beer/
    end

    it "zero balance (all even)" do
      @beer.balances['joshalbert'] = 1
      sendmsg("!give_beer albert").should =~ /albert .* even/
    end
  end

end

describe "demanding beer" do
  it "should respond to the command !demand_beer" do
    pending
  end
  
  it "should decrease my balance with the opposite party" do
    pending
  end
  
end

describe "redeeming beer" do
  it "should respond to the command !redeem_beer" do
    pending
  end
  
  it "should increase my balance with the opposite party" do
    pending    
  end
  
  it "should not increase my balance if it is already zero" do
    pending
  end
end

