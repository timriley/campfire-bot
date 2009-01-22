require 'spec'
BOT_ROOT        = File.join(File.dirname(__FILE__), '..')
BOT_ENVIRONMENT = 'test'

# require '../../tinder/lib/tinder'
require File.join(File.dirname(__FILE__), '../lib/bot.rb')
# require '../lib/event.rb'
# require '../lib/plugin.rb'
# require '../lib/message.rb'

module CampfireBot
  class Bot
  end

  class Plugin
  end
end

bot.config = []
bot.config[:nickname] = 'Bot'
require '../plugins/beer.rb'


describe "giving beer" do
  before(:each) do
    @beer = CampfireBot::Plugin::Beer.new()
    config = mock('config')
    bot.expects(:config).returns(config)
    config.expects(:[]).with('nickname').returns('Bot')
  end
  
  it "should respond to the command !give_beer" do
    @beer.give_beer('foo')
  end
end
