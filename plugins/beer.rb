require 'yaml'

class Beer < CampfireBot::Plugin
  
  # Beer::COMMAND_REGEXP = "^(?:!|#{bot.config['nickname']},\\s+)"
  
  # Beer::GIVE_REGEXP =  Regexp.new("#{Beer::COMMAND_REGEXP}([a-z\\s\\.]{4,12})([0-9]+)*", Regexp::IGNORECASE)
  # Beer::CREDIT_REGEXP = //
  # Beer::BALANCE_REGEXP = //
    
  # on_message @debit_matcher, :respond
  # on_message Regexp.new("#{CREDIT_REGEXP.source}", Regexp::IGNORECASE), :credit_cmd
  on_command 'give_beer', :give_beer
  on_command 'demand_beer', :demand_beer
  on_command 'redeem_beer', :redeem_beer 
  # on_command 'beer', :balance_cmd
  
  # parties sort alphabetically
  # john.b.josh w.: 1 (josh owes john a beer)
  # john.b.josh w.: -1 (john owes josh a beer)
  
  class BadArgumentException < Exception
  end
  
  def give_beer(msg)
    give_or_demand_beer(msg, :give)
  end
  
  def demand_beer(msg)
    give_or_demand_beer(msg, :demand)
  end
  
  def redeem_beer(msg)
    give_or_demand_beer(msg, :redeem)
  end
  
  # def get_balance(user1, user2)
  #   bal = balance(user1.downcase, user2.downcase)
  #    if bal > 0
  #       msg.speak("#{user1} owes #{user2} #{bal} beers")
  #     else
  #       msg.speak("#{user2} owes #{user1} #{bal} beers")
  #     end
  # end
  #   
  
  def give_or_demand_beer(msg, trans_type)     
    args = msg[:message].split(' ')
    
    trans_type_msg = {:give => 'give beer to', :demand => 'demand beer from', :redeem => 'redeem beer from'}[trans_type]
    
    begin
  
      if args[0].nil?
        raise BadArgumentException.new, "Sorry, I don't know whom to #{trans_type_msg}"
      end
      
      payee = args[0]
      speaker = msg[:person]
            
      if !args[1].nil? and args[1].to_i == 0
        raise BadArgumentException.new, "Sorry, I don't accept non-integer amounts"
      end
      
      amt = !args[1].nil? ? args[1].to_i : 1
      
      if amt <= 0
        raise BadArgumentException.new, "Sorry, I don't accept negative numbers as an argument"
      end
      
      case trans_type
      when :give
        amt = amt * -1 # this is a credit
      when :demand
        # no change - this is a debit
      when :redeem
        # no change - this is a debit
        if bal = balance(speaker, payee) == 0
          raise BadArgumentException.new, "#{payee} didn't owe you any beers to begin with."
        end
      end
      
      
      
      beer_transaction(speaker, payee, amt)

      bal = balance(speaker, payee)
      
      # puts "post transaction balance = #{bal}"
      if bal > 0
        msg.speak("Okay, you now owe #{payee} #{bal} beers")
      elsif bal < 0
        msg.speak("Okay, #{payee} now owes you #{bal * -1} beers")
      else
        msg.speak("Okay, you and #{payee} are now even")
      end
      
    rescue BadArgumentException => exception
      msg.speak(exception.message)
    end
    
  end
  
  
  def beer_transaction(user1, user2, amount)
    #beer_transaction user1, user2, -1 : user1 gives user2 a beer
    #beer_transaction user1, user2, 1 : user2 gives user1 a beer
    @balances = init()
    # puts 'beer_transaction'
    # p "beer_transaction start: #{@balances.inspect}"
    hash = get_hash(user1, user2)
    if !@balances.key?(hash)
      @balances[hash] = 0
    end
    @balances[hash] += amount
    # p "beer_transaction end: #{@balances.inspect}"
    write
    
  end
    
  
  
  def balance(user1, user2)
    # balance user1, user2 = 1 : user2 owes user1 a beer
    # balance user1, user2 = -1: user1 owes user2 a beer
    @balances = init()
    hash = get_hash(user1, user2)
    bal = @balances[hash]
    if bal.nil? 
      0
    else
      first_user = [user1, user2].min
      bal = bal * -1 if first_user == user1
      bal
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