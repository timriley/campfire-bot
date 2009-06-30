require 'spec'
BOT_ROOT        = File.join(File.dirname(__FILE__), '..')
BOT_ENVIRONMENT = 'test'

require File.join(File.dirname(__FILE__), '../lib/bot.rb')
bot = CampfireBot::Bot.instance
require "#{BOT_ROOT}/plugins/our_quotes.rb"

describe "OurQuotes plugin" do

  it "should remember added quotes" do
    when_saying "!addquote Someone: Hello world."
    bot_should_reply "Added quote #1."
    quotes[0].should == "Someone: Hello world."
  end

  it "should complain when !addquote is given without a quote" do
    when_saying "!addquote"
    bot_should_reply "Please include the text of the quote and attribution."
    quotes.size.should == 0
  end

  it "should regurgitate random quotes" do
    with_quote_log {
      add "Someone: Hello world."
    }
    when_saying "!quote"
    # How to show attribution, index, room, and timestamp?
    #bot_should_reply "Someone spake thusly: Hello world"
    #                 "Foo quoth thither
    bot_should_reply "#1 Someone: Hello world."
  end

  it "should find matching quotes" do
    with_quote_log {
      add "Anyone: Hello world."
      add "Someone: Hello world."
      del 1
      add "Someone: It's too cold."
    }
    when_saying "!quote o w"
    bot_should_reply "#2 Someone: Hello world. (1 match)"
  end

  it "should use proper grammer when showing number of matches" do
    with_quote_log {
      add "Anyone: hi!"
      add "Anyone: bye."
    }
    when_saying "!quote Anyone"
    bot_should_reply %r/ \(2 matches\)$/
  end

  it "should retrieve quotes by ID when the query is numeric" do
    with_quote_log {
      add "Anyone: 2+2"
      add "Anyone: hi!"
    }
    when_saying "!quote 2"
    bot_should_reply "#2 Anyone: hi!"
  end

  it "should display an explanation when !quote is given an invalid ID" do
    when_saying "!quote 1"
    bot_should_reply "No quote #1."
  end

  # Implementation idea: save array of matches in a hash
  # keyed by query and perhaps user.  Should expire after
  # a few minutes, so don't bother persisting it even to tmp/.
  it "should iterate through results on repeat command" do
    pending
    with_quote_log {
      add "Someone: Foo"
      add "Someone: Bar"
      add "Someone: Baz"
    }
    when_saying "!quote Someone"
    bot_should_reply %r/#\d Someone: ... \(3 matches\)$/
    when_saying "!quote Someone"
    bot_should_reply %r/#\d Someone: ... \(2 of 3 matches\)$/
    when_saying "!quote Someone"
    bot_should_reply %r/#\d Someone: ... \(3 of 3 matches\)$/
    # Or maybe (3 matches, none left) ?
  end

  it "should remove last quote upon request" do
    with_quote_log {
      add "Hello world."
    }
    when_saying "!rmquote 1"
    bot_should_reply "Deleted quote #1."
    @quote.quotes.size.should == 0
  end

  it "should free trailing IDs when removing quotes" do
    with_quote_log {
      add "One"
      add "Two"
      add "Three"
      add "Four"
      del 3
      del 4
      add "III"
    }
    quotes[3 - 1].should == "III"
  end

  it "should preserve IDs of quotes after the removed one" do
    with_quote_log {
      add "One"
      add "Two"
      add "Three"
      del 2
    }
    quotes[3 - 1].should == "Three"
  end

  it "should display an explanation when !rmquote is given an invalid ID" do
    when_saying "!rmquote 1"
    bot_should_reply "No quote #1."
  end

  it "should save quotes between runs" do
    with_quote_log {
      add "One"
      add "Two"
    }
    init_plugin # Should re-read the .yml file
    quotes[2 - 1].should == "Two"
  end

  it "should handle angle brackets appropriately" do
    # One convention for attribution is to place the speaker in brackets.
    # And this is how Campfire+Tinder+CampfireBot send us the message.
    when_saying "!addquote \\u0026lt;Someone\\u0026gt; Hello"
    bot_should_reply "Added quote #1."
    quotes[1 - 1].should == "<Someone> Hello"
  end


  before :each do
    @bot = CampfireBot::Bot.instance
    @bot.stub!(:config).and_return('nickname' => 'Bot',
                                   'our_quotes_recall_command' => 'quote'
                                   #,'our_quotes_debug_enabled' => true
                                   )
    init_plugin
  end
  after :each do
    if File.exist? @quote.data_file
      File.unlink(@quote.data_file)
    end
  end
  def init_plugin
    @quote = OurQuotes.new
    CampfireBot::Plugin.registered_plugins['OurQuotes'] = @quote
  end

  def when_saying(msg)
    @message = CampfireBot::Message.new(:room => Tinder::Room.new(42, "Room1"),
                                        :message => msg,
                                        :person => 'Josh')
  end
  def bot_should_reply(msg)
    @message.should_receive(:speak).with(msg)
    @bot.send(:handle_message, @message)
  end

  # Group log setup calls into a block
  def with_quote_log
    yield
  end
  # Add a quote to the log
  def add(quote)
    @quote.append_add("Someoneelse", "Room1", quote)
  end
  # Remove a quote from the log by id
  def del(quote_id)
    @quote.append_del("Someoneelse", "Room1", quote_id)
  end
  def quotes
    @quote.quotes
  end

end
