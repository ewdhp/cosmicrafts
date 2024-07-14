// Types.mo
import Time "mo:base/Time";

module {
  public type PlayerId = Principal;
  public type UserID = Principal;
  public type Username = Text;
  public type AvatarID = Nat;
  public type Description = Text;
  public type RegistrationDate = Time.Time;

  public type PlayerName = Text;
  public type Level = Nat;
  public type GameID = Principal;
  public type Players = Principal;
  public type UserRecord = {
    userId : UserID;
    username : Username;
    avatar : AvatarID;
    friends : [UserID];
    description : Description;
    registrationDate : RegistrationDate;
  };
  public type FriendDetails = {
    userId : UserID;
    username : Username;
    avatar : AvatarID;
  };
  public type Player = {
    id : PlayerId;
    name : PlayerName;
    level : Level;
    elo : Float;
  };
  public type PlayerPreferences = {
    language : Nat;
    playerChar : Text;
  };
  public type UserDetails = { user : UserRecord; friends : [FriendDetails] };

  // Statistics
  public type StastisticsGameID = Nat;
  public type PlayerID = Principal;

  public type GamesWithFaction = {
    factionID : Nat;
    gamesPlayed : Nat;
    gamesWon : Nat;
  };

  public type GamesWithGameMode = {
    gameModeID : Nat;
    gamesPlayed : Nat;
    gamesWon : Nat;
  };

  public type GamesWithCharacter = {
    characterID : Text;
    gamesPlayed : Nat;
    gamesWon : Nat;
  };

  public type BasicStats = {
    energyUsed : Float;
    energyGenerated : Float;
    energyWasted : Float;
    energyChargeRate : Float;
    xpEarned : Float;
    damageDealt : Float;
    damageTaken : Float;
    damageCritic : Float;
    damageEvaded : Float;
    kills : Float;
    deploys : Float;
    secRemaining : Float;
    wonGame : Bool;
    faction : Nat;
    characterID : Text;
    gameMode : Nat;
    botMode : Nat;
    botDifficulty : Nat;
  };

  public type PlayerGamesStats = {
    gamesPlayed : Nat;
    gamesWon : Nat;
    gamesLost : Nat;
    energyGenerated : Float;
    energyUsed : Float;
    energyWasted : Float;
    totalDamageDealt : Float;
    totalDamageTaken : Float;
    totalDamageCrit : Float;
    totalDamageEvaded : Float;
    totalXpEarned : Float;
    totalGamesWithFaction : [GamesWithFaction];
    totalGamesGameMode : [GamesWithGameMode];
    totalGamesWithCharacter : [GamesWithCharacter];
  };

  public type OverallStats = {
    totalGamesPlayed : Nat;
    totalGamesSP : Nat;
    totalGamesMP : Nat;
    totalDamageDealt : Float;
    totalTimePlayed : Float;
    totalKills : Float;
    totalEnergyGenerated : Float;
    totalEnergyUsed : Float;
    totalEnergyWasted : Float;
    totalXpEarned : Float;
    totalGamesWithFaction : [GamesWithFaction];
    totalGamesGameMode : [GamesWithGameMode];
    totalGamesWithCharacter : [GamesWithCharacter];
  };

  public type AverageStats = {
    averageEnergyGenerated : Float;
    averageEnergyUsed : Float;
    averageEnergyWasted : Float;
    averageDamageDealt : Float;
    averageKills : Float;
    averageXpEarned : Float;
  };

  // Rewards
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

  // Matchmaking
  public type UserId = Principal;
  public type PlayerInfo = {
    id : UserId;
    matchAccepted : Bool;
    elo : Float;
    playerGameData : Text;
    lastPlayerActive : Nat64;
  };
  public type FullPlayerInfo = {
    id : UserId;
    matchAccepted : Bool;
    elo : Float;
    playerGameData : Text;
    playerName : Text;
  };
  public type MatchmakingStatus = {
    #Searching;
    #Reserved;
    #Accepting;
    #Accepted;
    #InGame;
    #Ended;
  };
  public type PlayerStatus = {
    status : MatchmakingStatus;
    matchID : Nat;
  };

  public type MatchData = {
    gameId : Nat;
    player1 : PlayerInfo;
    player2 : ?PlayerInfo;
    status : MatchmakingStatus;
  };

  public type FullMatchData = {
    gameId : Nat;
    player1 : FullPlayerInfo;
    player2 : ?FullPlayerInfo;
    status : MatchmakingStatus;
  };

  public type SearchStatus = {
    #Assigned;
    #Available;
    #NotAvailable;
  };
}
