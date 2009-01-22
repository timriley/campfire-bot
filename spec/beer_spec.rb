require 'spec'
BOT_ROOT        = File.join(File.dirname(__FILE__), '..')
BOT_ENVIRONMENT = 'test'

require File.join(File.dirname(__FILE__), '../lib/bot.rb')

describe "giving beer" do
  before(:all) do
    bot = CampfireBot::Bot.instance
    # bot.config = []
    bot.stub!('config').and_return({'nickname' => 'foo'})
    require "#{BOT_ROOT}/plugins/beer.rb"
    @beer = Beer.new() 
  end
  
  it "should respond to the command !give_beer" do
    @message = mock('message')
    @message.stub!(:[]).with(:person).and_return('Josh')
    @message.stub!(:[]).with(:message).and_return('!give_beer Bot')
    @message.should_receive(:speak)
    @beer.give_beer(@message)
  end
  
  it "should increase my balance with Bot" do
    @message = mock('message')
    @message.stub!(:[]).with(:message).and_return('!give_beer Foo')
    @message.stub!(:[]).with(:person).and_return('Josh')
    @message.should_receive(:speak)
    
    bal = @beer.balance('Josh', 'Foo')
    @beer.give_beer(@message)
    @beer.balance('Josh', 'Foo').should eql(bal - 1)
    
  end
  
end
