require 'yaml'

class Beer < CampfireBot::Plugin
  
  Beer::COMMAND_REGEXP = "^(?:!|#{bot.config['nickname']},\\s+)"
  
  Beer::GIVE_REGEXP =  Regexp.new("#{Beer::COMMAND_REGEXP}([a-z\\s\\.]{4,12})([0-9]+)*", Regexp::IGNORECASE)
  Beer::CREDIT_REGEXP = //
  Beer::BALANCE_REGEXP = //
    
  on_message @debit_matcher, :respond
  on_message Regexp.new("#{CREDIT_REGEXP.source}", Regexp::IGNORECASE), :credit_cmd
  on_command 'give_beer', :give_beer
  on_command 'demand_beer', :demand_beer
  on_command 'redeem_beer', :redeem_beer 
  on_command 'beer', :balance_cmd
  
  # parties sort alphabetically
  # john.b.josh w.: -1 (josh owes john a beer)
  # john.b.josh w.: 1 (john owes josh a beer)
  
  def give_beer(msg)     
    args = msg[:message].split(' ')
        
    puts msg[:person]
    if !args[0].nil?
      person1 = args[0]
      speaker = msg[:person]
      
      amt = !args[1].nil? ? args[1].to_i : 1
      beer_transaction(person1, speaker, amt)
      bal = balance(person1, speaker)
      if bal > 0
        msg.speak("Okay, you now owe #{person1} #{bal} beers ")
      elsif bal < 0
        msg.speak("Okay, #{person1} now owes you #{bal} beers ")
      elsif bal == 0
        msg.speak("Okay, you and #{person1} are now even")
      end
    end
  end
  
  def credit_cmd(msg)
    
  end
  
  def balance_cmd(msg)
    
  end
  
  
  def beer_transaction(user1, user2, amount)
    @balances = init()
    hash = get_hash(user1, user2)
    if !@balances.key?(hash)
      @balances[hash] = 0
    end
    @balances[hash] += amount
    write
    
  end
  
  def balance(user1, user2)
    hash = get_hash(user1, user2)
    bal = @balances[hash]
    first_user = [user1, user2].max
    bal =* -1 if first_user == user1
    bal
  end
  
  def all_balances(user1)
    
  end
  
  def get_bal
    bal = balance(user1, user2)
     if bal > 0
        msg.speak("#{user1} owes #{user2} #{bal} beers")
      else
        msg.speak("#{user2} owes #{user1} #{bal} beers")
      end
  end 
    
    
  def get_hash(user_1, user_2)
    user1 = user_1.downcase
    user2 = user_2.downcase
    
    if user1 > user2
      "#{user1}#{user2}"
    else
      "#{user2}#{user1}"
    end
  end
  
  
  def respond(msg)
    # puts "entering respond()"
    @balances = init()
    puts msg[:message]
    puts msg[:message] =~ RESPOND_REGEXP 
    puts $1, $2, $3
    if !@balances.has_key?($2.downcase)
      msg.speak("Sorry, I don't know what #{$2} is.")
    else
      fact = @balances[$2.downcase]
      msg.speak("#{msg[:person].split(" ")[0]}, #{$2} is #{fact}.")
    end
  end
  
  def define(msg)
    # puts 'entering define()'
    @balances = init()
    # puts @balances
    # puts msg[:message]
    # puts msg[:message] =~ Regexp.new("^#{bot.config['nickname']},\\s+#{DEFINE_REGEXP.source}", Regexp::IGNORECASE)
    # puts @define_regexp
    # puts $1, $2, $3
    @balances[$2.downcase] = $3
    msg.speak("Okay, #{$2} is now #{$3}")
  end
  
  def init
    # puts "entering init()"
    YAML::load(File.read(File.join(BOT_ROOT, 'tmp', 'beer.yml')))
  end
  
  def write
    File.open(File.join(BOT_ROOT, 'tmp', 'beer.yml'), 'w') do |out|
      YAML.dump(@balances, out)
    end
    
  end
  
  
  def reload(msg)
    @balances = init()
    speak("ok, reloaded #{@balances.size} balances")
  end
  
end