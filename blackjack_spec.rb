require_relative 'blackjack'

describe BettingStrategy do
  it 'hits if total is less than stopping limit' do
    BettingStrategy.new(15).hit?(14).should be_true
  end
  it 'does not hit if total is greater than or equal to stopping limit' do
    BettingStrategy.new(15).hit?(15).should be_false
    BettingStrategy.new(15).hit?(17).should be_false
  end
end

describe Player do
  let(:funds) { 100 }
  let(:strategy) { stub }
  let(:name) { "Bob Blackjack" }
  let(:player) { Player.new(funds, strategy, name) }

  it 'can bet funds' do
    amount = 5
    player.bet(amount)
    player.funds.should == funds - 5 
  end

  it 'can earn funds' do
    amount = 5
    player.earn(amount)
    player.funds.should == funds + 5 
  end

  it 'knows if it wants to hit according to its betting strategy' do
    total = stub
    strategy.stub(:hit?).with(total).and_return(true)
    player.hit?(total).should be_true
    strategy.stub(:hit?).with(total).and_return(false)
    player.hit?(total).should be_false
  end
end

describe PlayerBlackjackHand do
  let(:player) { stub }
  it 'receives two cards if the player decides not to hit at all' do
    player.stub(:hit?).and_return(false)
    Deck.should_receive(:random_card).and_return(10, 7)
    PlayerBlackjackHand.generate(player).should == 17 
  end
  it 'receives more cards if the player wants to hit' do
    player.stub(:hit?).and_return(true, false)
    Deck.should_receive(:random_card).and_return(10, 7, 2)
    PlayerBlackjackHand.generate(player).should == 19 
  end
  it 'will generate a bust hand for a player with bad luck' do
    player.stub(:hit?).and_return(true)
    Deck.should_receive(:random_card).and_return(10, 7, 2, 10)
    PlayerBlackjackHand.generate(player).should == 29 
  end
end

describe DealerBlackjackHand do
  context "when the player busted" do
    it 'does not require any cards to win' do
      DealerBlackjackHand.generate(23).should == 0
    end
  end
  context "when the player has stopped at less than 21" do
    it 'hits until it wins' do
      Deck.should_receive(:random_card).and_return(5, 6, 10)
      DealerBlackjackHand.generate(20).should == 21
    end
    it 'hits until it busts if the player is winning' do
      Deck.should_receive(:random_card).and_return(10, 9, 10)
      DealerBlackjackHand.generate(20).should == 29 
    end
  end
  context "when the player has 21" do
    it 'does not require any cards since the player has won' do
      DealerBlackjackHand.generate(21).should == 0
    end
  end
end

describe Round do
  let(:bet_amount) { 5 }
  let(:win_amount) { 2 * bet_amount }
  let(:player) { stub.as_null_object }
  let(:round) { Round.new(bet_amount, player) }

  before do
    PlayerBlackjackHand.stub(:generate).and_return(player_total)
    DealerBlackjackHand.stub(:generate).and_return(dealer_total)
  end

  describe 'playing a round' do
    let(:player_total) { 19 }
    let(:dealer_total) { 23 }

    it 'collects the player bet' do
      player.should_receive(:bet).with(bet_amount)
      round.play
    end

    context 'when player wins' do
      it 'pays the player' do
        player.should_receive(:earn).with(win_amount)
        round.play
      end
    end

    context 'when the player wins with 21' do
      let(:player_total) { 21 }
      let(:dealer_total) { 0 }

      it 'pays the player' do
        player.should_receive(:earn).with(win_amount)
        round.play
      end
    end

    context 'when player loses without busting' do
      let(:player_total) { 17 }
      let(:dealer_total) { 18 }

      it 'does not pay the player' do
        player.should_not_receive(:earn).with(win_amount)
        round.play
      end
    end

    context 'when player loses with busting' do
      let(:player_total) { 23 }
      let(:dealer_total) { 0 }

      it 'does not pay the player' do
        player.should_not_receive(:earn).with(win_amount)
        round.play
      end
    end
  end
end

describe BlackjackSimulation do
  let(:bet_amount) { 20 }
  let(:players) { stub }
  let(:simulation) { BlackjackSimulation.new(bet_amount, players) }
  let(:player_without_money) { stub(:funds => 0) }
  let(:player_with_money) { stub(:funds => 10000) }
  let(:player_with_less_than_bet) { stub(:funds => (bet_amount - 1)) }

  context "Ending the simulation" do
    it 'is not over if more than one player has money left' do
      simulation.players = [player_with_money, player_with_money]
      simulation.should_not be_over
    end

    it 'is over if only one player has money left' do
      simulation.players = [player_without_money, player_with_money]
      simulation.should be_over
    end
  end

  context "Playing a round" do
    it 'asks each player with enough funds to play a round' do
      simulation.players = [player_with_money, 
                            player_without_money, 
                            player_with_less_than_bet] 
      round = stub
      Round.stub(:new).with(bet_amount, player_with_money).and_return(round)
      round.should_receive(:play)
      simulation.play_round
    end
  end
end
