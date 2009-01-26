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
  on_command 'balance', :balance_cmd
  
  # balances: {'josh' => {'party1' => 1 }, 'party1': '}
  
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
  
  def balance_cmd(msg)
    @balances = init()
    begin
      if msg[:message].empty?
        return
        # raise BadArgumentException.new, "Sorry, I don't know whom to #{trans_type_msg}"
      end
                
      speaker = msg[:person]
      payee = msg[:message]
      
      bal = balance(speaker, payee)
      
      units = bal.abs == 1 ? "beer" : "beers"
      
      if bal < 0
        msg.speak("#{payee} owes you #{bal * -1} #{units}")
      elsif bal > 0
        msg.speak("You owe #{payee} #{bal} #{units}")
      else
        msg.speak("You and #{payee} are even")
      end
        
      rescue BadArgumentException => exception
        msg.speak(exception.message)
      end
  end
  
  
  def give_or_demand_beer(msg, trans_type)     
    args = msg[:message].match(/(^[a-z\s\.\-]+?)(\s*\-*[0-9]*)$/i)
    # puts "args = #{args.inspect}"
    # puts "args[0] = #{args[0]}"
    # puts "args[1] = #{args[1]}"
    # puts "args[2] = #{args[2]}"

    trans_type_msg = {:give => 'give beer to', :demand => 'demand beer from', :redeem => 'redeem beer from'}[trans_type]
    
    begin
  
      if args.nil?
        raise BadArgumentException.new, "Sorry, I don't know whom to #{trans_type_msg}"
      end
      
      payee = args[1].strip
      speaker = msg[:person]
            
      if args[2] != "" and args[2].to_i == 0
        raise BadArgumentException.new, "Sorry, I don't accept non-integer amounts"
      end
      
      amt = args[2] != "" ? args[2].to_i : 1
      
      if amt <= 0
        raise BadArgumentException.new, "Sorry, I don't accept negative numbers as an argument"
      end
      
      case trans_type
      when :give
        # no change - this is a debit
      when :demand
        amt = amt * -1 # this is a credit
      when :redeem
        # amt = amt * -1 # this is a credit
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
    #beer_transaction user1, user2, 1 : user1 owes user2 a beer
    #beer_transaction user1, user2, -1 : user1 demands a beer from user2 (user1 owes user2 -1 beers)
    @balances = init()
    # puts 'beer_transaction'
    # p "beer_transaction start: #{@balances.inspect}"
    # p "beer_transaction args: #{user1}, #{user2}, #{amount}"
    user1 = user1.downcase.strip
    user2 = user2.downcase.strip
    
    if !@balances.key?(user1)
      @balances[user1] = {}
    end
    
    if !@balances[user1].key?(user2)
      @balances[user1][user2] = 0
    end
    
    @balances[user1][user2] += amount
    
    # p "beer_transaction end: #{@balances.inspect}"
    write
    
  end
    
  
  
  def balance(user1, user2)
    # verb => user1 owes user2 #{balance} beers
    # bal(user1, user2) = 1 # user1 is owed a beer from user2
    # bal(user1, user2) = -1 # user1 is owed -1 beers from user 2 (meaning user2 owes user1)
    
    @balances = init()
    
    # puts "hash is #{hash}, @balances[#{hash}] = #{@balances[hash]}"
    user1 = user1.downcase.strip
    user2 = user2.downcase.strip
    
    if @balances.key?(user1) and @balances[user1].key?(user2)
      bal1 = @balances[user1][user2]
    else 
      bal1 = 0
    end
    
    if @balances.key?(user2) and @balances[user2].key?(user1)
      bal2 = @balances[user2][user1]
    else 
      bal2 = 0
    end
    
    bal = bal1 - bal2
    
    if (@balances.key?(user1) ? !@balances[user1].key?(user2) : true) and 
      (@balances.key?(user2) ? !@balances[user2].key?(user1) : true)
      raise BadArgumentException.new, "Sorry, you don't have any beer transactions with anyone named #{user2}"
    end
    
    bal
  end
    
  def get_hash(user_1, user_2)
    user1 = user_1.downcase
    user2 = user_2.downcase
    
    [user1,user2].sort.to_s
    # if user1 < user2
    #   "#{user1}#{user2}"
    # else
    #   "#{user2}#{user1}"
    # end
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
