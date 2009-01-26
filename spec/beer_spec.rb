require 'spec'
BOT_ROOT        = File.join(File.dirname(__FILE__), '..')
BOT_ENVIRONMENT = 'development'

require File.join(File.dirname(__FILE__), '../lib/bot.rb')
bot = CampfireBot::Bot.instance
require "#{BOT_ROOT}/plugins/beer.rb"


class SpecMessage < CampfireBot::Message
  attr_reader :response
  
  #overwrite message.speak method so that we can expose the output
  def speak(msg)
    # puts "specmessage.speak(#{msg})"
    @response = msg
  end
  
end 

class SpecBeer < CampfireBot::Plugin::Beer
  attr_accessor :balances
end

# send a message to the room and return the response
def sendmsg(msg)
  # puts "sendmsg(#{msg})"
  @message[:message] = msg
  bot.send(:handle_message, @message)
  # puts "sendmsg returns #{@message.response}"
  @message.response
end

# instantiate the bot and the plugin fresh
def setup
  bot = CampfireBot::Bot.instance
  bot.stub!(:config).and_return({'nickname' => 'Bot'})
  @beer = SpecBeer.new()
  CampfireBot::Plugin.registered_plugins['Beer'] = @beer
  @message = SpecMessage.new(:person => 'Josh')
  @beer.balances = {}
  @beer.stub!(:init).and_return(@beer.balances)
  @beer.stub!(:write)
  puts @beer.balances
  @message = SpecMessage.new(:person => 'Josh')
end

describe "giving beer" do
  before(:each) do
    setup
  end
  
  it "should respond to the command !give_beer" do
    @beer.should_receive(:give_beer)
    sendmsg "!give_beer"
  end
  

  it "should increase my balance with Foo" do
    bal = 0
    sendmsg '!give_beer Foo'
    @beer.balance('Josh', 'Foo').should eql(bal + 1)
  end

  
  it "should say back to me what my balance is" do
     
     sendmsg('!give_beer bruce').should =~ /1/
  end
  
  it "should accept an argument of the number of beers to credit" do
    bal = 2
    sendmsg('!give_beer harvey 2')
    @beer.balance('Josh', 'harvey').should eql(bal)
  end

  it "should handle nicely names with spaces in them with no argument" do
    bal = 1
    sendmsg('!give_beer harvey A.')
    @beer.balance('Josh', 'harvey A.').should eql(bal)
  end

  it "should handle nicely names with spaces in them and an argument" do
    bal = 2
    sendmsg('!give_beer harvey D. 2')
    @beer.balance('Josh', 'harvey D.').should eql(bal)
  end

  it "should not accept negative numbers as an argument" do
    sendmsg('!give_beer harvey -2').should =~ /negative number/
  end
  
end

describe "demanding beer" do
  
  before(:each) do
    setup
  end
  
  it "should respond to the command !demand_beer" do
    @beer.should_receive(:demand_beer)
    sendmsg("!demand_beer albert")
  end
  
  it "should decrease my balance with the opposite party" do
    bal = 0
    # p "initial bal is #{bal}"
    sendmsg '!demand_beer Foo'
    puts @beer.balance('Josh', 'Foo')
    @beer.balance('Josh', 'Foo').should eql(bal - 1)
  end
  
end

describe "redeeming beer" do
  before(:each) do
    setup
  end
  
  it "should respond to the command !redeem_beer" do
    @beer.should_receive(:redeem_beer)
    sendmsg('!redeem_beer Foo')
    
  end
  
  it "should increase my balance with the opposite party (redeeming is the same as giving)" do
    sendmsg '!demand_beer albert'
    sendmsg '!demand_beer albert'
    bal = @beer.balance('Josh', 'albert')
    # puts "------  #{bal}"
    sendmsg '!redeem_beer albert'
    @beer.balance('Josh', 'albert').should eql(bal + 1)
  end
  
  it "should not increase my balance if it is already zero" do
    @beer.should_receive('balance').with('Josh', 'bill').and_return(0)
    sendmsg("!redeem_beer bill").should =~ /to begin with/
    # @beer.balance('Josh', 'bill').should eql(bal)
  end
end


describe "should have the correct reply for" do
  
  before(:each) do
    setup
  end

  it "negative balances (I owe beers)" do
    @beer.should_receive('balance').with('Josh', 'james').and_return(1)
    sendmsg("!give_beer james").should =~ /you now owe james .* beer/
  end
  
  it "positive balances (I am owed beers)" do
    @beer.balances['albert'] = {}
    @beer.balances['albert']['Josh'] = 1
    sendmsg("!demand_beer albert").should =~ /albert now owes you .* beer/
  end
  
  it "zero balance (all even)" do
    @beer.should_receive('balance').with('Josh', 'albert').and_return(0)
    sendmsg("!give_beer albert").should =~ /albert .* even/
  end
  
  it "missing all arguments" do
    sendmsg("!give_beer").should =~ /don't know whom/
  end
  
  # it "non-integer 2nd arg" do
  #     sendmsg("!give_beer albert non-int").should =~ /I don't accept non-integer amounts/
  #   end
  
end

describe "!balance command" do
  before(:each) do
    setup
  end
  
  it "should respond to the !balance command" do
    @beer.should_receive(:balance_cmd)
    sendmsg("!balance")
  end
  
  it "should require an argument of a user" do
    sendmsg("!balance").should be_nil
  end
  
  describe "should return the correct balance for" do
    it "negative balances" do
      sendmsg("!demand_beer maxim 2")
      # @beer.balance('Josh', 'max').should eql(-2)
      # @beer.should_receive('balance').with('Josh', 'Foo').and_return(-1)
      sendmsg("!balance maxim").should =~ /owes you 2 beers/
    end
    
    it "positive balances" do
      sendmsg("!give_beer maximo 9")
      # @beer.balance('Josh', 'max').should eql(7)
      # @beer.should_receive('balance').with('Josh', 'Foo').and_return(1)
      sendmsg("!balance maximo").should =~ /You owe .* 9 beers/
    end
    
    it "non-existent balances" do
      sendmsg("!balance Fsdfsdfsdfsdfsdfoo").should =~ /transactions/
    end
    
  end
end

describe "beer_transactiona and balance" do
  it "should handle equivalent transactions equivalently" do
    pending
  end
  
  
end
