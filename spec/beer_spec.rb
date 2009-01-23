require 'spec'
BOT_ROOT        = File.join(File.dirname(__FILE__), '..')
BOT_ENVIRONMENT = 'development'

require File.join(File.dirname(__FILE__), '../lib/bot.rb')

describe "giving beer" do
  before(:all) do
    bot = CampfireBot::Bot.instance
    # bot.config = []
    # bot.stub!(:config).and_return({'nickname' => 'foo'})
    # bot.send(:load_plugins)
    require "#{BOT_ROOT}/plugins/beer.rb"
    CampfireBot::Plugin.registered_plugins['Beer'] = CampfireBot::Plugin::Beer.new()
    @beer = CampfireBot::Plugin.registered_plugins['Beer']
  end
  
  it "should respond to the command !give_beer" do

    @message = CampfireBot::Message.new(:person => 'Josh', :message => '!give_beer')
    @beer.should_receive(:give_beer)
    bot.send(:handle_message, @message)
  
  end
  
  it "should increase my balance with Foo" do
    @message = CampfireBot::Message.new(:person => 'Josh', :message => '!give_beer Foo')
    
    bal = @beer.balance('Josh', 'Foo')
    # @beer.should_receive(:give_beer)
    # @beer.should_receive(:beer_transaction)
    @message.stub!(:speak)
    
    p "initial bal is #{bal}"
    bot.send(:handle_message, @message)
    p 'sent message'
    
    @beer.balance('Josh', 'Foo').should eql(bal - 1)
  end
  
  it "should say back to me what my balance is" do
    @message = CampfireBot::Message.new(:person => 'Josh', :message => '!give_beer Foo')
    @message.should_receive(:speak)
    
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


