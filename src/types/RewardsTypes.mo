module {
  public type GameID = Nat;
  public type PlayerID = Principal;

  public type RewardType = {
    #GamesCompleted;
    #GamesWon;
    #LevelReached;
  };

  public type PrizeType = {
    #Chest;
    #Flux;
    #Shards;
  };

  public type Reward = {
    id : Nat;
    rewardType : RewardType;
    name : Text;
    prize_type : PrizeType;
    prize_amount : Nat;
    start_date : Nat64;
    end_date : Nat64;
    total : Float;
  };

  public type RewardsUser = {
    id_reward : Nat;
    total : Float;
    progress : Float;
    finished : Bool;
    finish_date : Nat64;
    start_date : Nat64;
    expiration : Nat64;
    rewardType : RewardType;
    prize_type : PrizeType;
    prize_amount : Nat;
  };

  public type RewardProgress = {
    rewardType : RewardType;
    progress : Float;
  };

};
