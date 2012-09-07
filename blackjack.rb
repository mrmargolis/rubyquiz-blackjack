class BettingStrategy
  def initialize(stopping_limit)
    @stopping_limit = stopping_limit
  end

  def hit?(total)
    total < @stopping_limit
  end
end

class Player < Struct.new(:funds, :strategy, :name)
  def bet(amount)
    self.funds -= amount
  end

  def earn(amount)
    self.funds += amount
  end

  def hit?(total)
    strategy.hit?(total)
  end
end

class Deck
  LOW_CARDS = (1..9).to_a * 4
  HIGH_CARDS = [10] * 4 * 4
  CARDS = LOW_CARDS + HIGH_CARDS

  def self.random_card
    CARDS.shuffle.first
  end
end

class PlayerBlackjackHand
  def self.generate(player)
    total = Deck.random_card + Deck.random_card
    while player.hit?(total) && total < 21
      total += Deck.random_card
    end
    return total
  end
end

class DealerBlackjackHand
  def self.generate(player_total)
    return 0 if player_total >= 21
    total = Deck.random_card + Deck.random_card
    while (total < player_total && total <= 21)
      total += Deck.random_card
    end 
    return total
  end
end

class Round < Struct.new(:bet_amount, :player)
  def play
    collect_bet
    deal_cards
    resolve_bets
  end

  def collect_bet
    player.bet(bet_amount)
  end

  def deal_cards
    @player_total = PlayerBlackjackHand.generate(player)
    @dealer_total = DealerBlackjackHand.generate(@player_total)
  end

  def resolve_bets
    player.earn(2 * bet_amount) if player_won?
  end

  def player_won?
    @dealer_total > 21 || ((@player_total <= 21) && (@dealer_total < @player_total))
  end
end

class BlackjackSimulation
  attr_accessor :players 

  def initialize(bet_amount, players)
    @bet_amount = bet_amount
    @players = players
  end

  def play_simulation
    loop { play_round; break if over? }
  end

  def over?
    @players.select {|player| player.funds > 0 }.length <= 1
  end

  def play_round
    players_with_funds.each do |player|
      Round.new(@bet_amount, player).play
    end
  end

  def players_with_funds
    @players.select{|x| x.funds >= @bet_amount  }
  end
end

if ENV['RUN']
  clara = Player.new(500, BettingStrategy.new(16), "clara16")
  bob = Player.new(500, BettingStrategy.new(17), "bob17")
  ralph = Player.new(500, BettingStrategy.new(18), "ralph18")
  nickie = Player.new(500, BettingStrategy.new(20), "nickie20")
  simulation = BlackjackSimulation.new(5, [clara, bob, ralph, nickie])
  start_time = Time.now
  simulation.play_simulation
  simulation.players.each do |player|
    puts "#{player.name}: #{player.funds}"
  end
  puts "Took #{Time.now - start_time} time"
end
