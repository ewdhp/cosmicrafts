import Time "mo:base/Time";

module Types {
  // General Types
  public type PlayerId = Principal;
  public type Username = Text;
  public type AvatarID = Nat;
  public type Description = Text;
  public type RegistrationDate = Time.Time;
  public type Level = Nat;
  public type MatchID = Nat;
  public type TokenID = Nat;

  public type MatchResult = Text;
  public type MatchMap = Text;
  public type PlayerFaction = Text;
  public type Faction = Text;

  // Player and Friend Details
  public type Player = {
    id: PlayerId;
    username: Username;
    avatar: AvatarID;
    description: Description;
    registrationDate: RegistrationDate;
    level: Level;
    elo: Float;
    friends: [FriendDetails];
  };

  public type FriendDetails = {
    playerId: PlayerId;
    username: Username;
    avatar: AvatarID;
  };

  // Statistics
  public type PlayerStats = {
    playerId: PlayerId;
    energyUsed: Nat;
    energyGenerated: Nat;
    energyWasted: Nat;
    energyChargeRate: Nat;
    xpEarned: Nat;
    damageDealt: Nat;
    damageTaken: Nat;
    damageCritic: Nat;
    damageEvaded: Nat;
    kills: Nat;
    deploys: Nat;
    secRemaining: Nat;
    wonGame: Bool;
    faction: Nat;
    characterID: Nat;
    gameMode: Nat;
    botMode: Nat;
    botDifficulty: Nat;
  };

  public type BasicStats = {
    playerStats: [PlayerStats];
  };

  public type PlayerGamesStats = {
    gamesPlayed: Nat;
    gamesWon: Nat;
    gamesLost: Nat;
    energyGenerated: Nat;
    energyUsed: Nat;
    energyWasted: Nat;
    totalKills: Nat;
    totalDamageDealt: Nat;
    totalDamageTaken: Nat;
    totalDamageCrit: Nat;
    totalDamageEvaded: Nat;
    totalXpEarned: Nat;
    totalGamesWithFaction: [GamesWithFaction];
    totalGamesGameMode: [GamesWithGameMode];
    totalGamesWithCharacter: [GamesWithCharacter];
  };

  public type GamesWithFaction = {
    factionID: Nat;
    gamesPlayed: Nat;
    gamesWon: Nat;
  };

  public type GamesWithGameMode = {
    gameModeID: Nat;
    gamesPlayed: Nat;
    gamesWon: Nat;
  };

  public type GamesWithCharacter = {
    characterID: Nat;
    gamesPlayed: Nat;
    gamesWon: Nat;
  };

  public type AverageStats = {
    averageEnergyGenerated: Nat;
    averageEnergyUsed: Nat;
    averageEnergyWasted: Nat;
    averageDamageDealt: Nat;
    averageKills: Nat;
    averageXpEarned: Nat;
  };

  public type OverallStats = {
    totalGamesPlayed: Nat;
    totalGamesSP: Nat;
    totalGamesMP: Nat;
    totalDamageDealt: Nat;
    totalTimePlayed: Nat;
    totalKills: Nat;
    totalEnergyGenerated: Nat;
    totalEnergyUsed: Nat;
    totalEnergyWasted: Nat;
    totalXpEarned: Nat;
    totalGamesWithFaction: [OverallGamesWithFaction];
    totalGamesGameMode: [OverallGamesWithGameMode];
    totalGamesWithCharacter: [OverallGamesWithCharacter];
  };

    public type OverallGamesWithFaction = {
    factionID: Nat;
    gamesPlayed: Nat;
  };

  public type OverallGamesWithGameMode = {
    gameModeID: Nat;
    gamesPlayed: Nat;
  };

  public type OverallGamesWithCharacter = {
    characterID: Nat;
    gamesPlayed: Nat;
  };

  // Missions Types
  public type MissionType = {
    #GamesCompleted;
    #GamesWon;
    #LevelReached;
    #DamageDealt;
    #DamageTaken;
    #EnergyUsed;
    #UnitsDeployed;
    #FactionPlayed;
    #GameModePlayed;
    #XPEarned;
    #Kills;
  };

  public type RewardType = {
    #Chest;
    #Flux;
    #Shards;
  };

  public type MissionOption = {
    MissionType: MissionType;
    minAmount: Nat;
    maxAmount: Nat;
    rarity: Nat;
  };

  public type Mission = {
    id: Nat;
    missionType: MissionType;
    name: Text;
    reward_type: RewardType;
    reward_amount: Nat;
    start_date: Nat64;
    end_date: Nat64;
    total: Nat;
  };

  public type MissionsUser = {
    id_mission: Nat;
    total: Nat;
    progress: Nat;
    finished: Bool;
    finish_date: Nat64;
    start_date: Nat64;
    expiration: Nat64;
    missionType: MissionType;
    reward_type: RewardType;
    reward_amount: Nat;
  };

  public type MissionProgress = {
    missionType: MissionType;
    progress: Nat;
  };

  public type MissionTemplate = {
    name: Text;
    missionType: MissionType;
    rewardType: RewardType;
    minReward: Nat;
    maxReward: Nat;
    total: Nat;
    hoursActive: Nat64;
  };

  public type RewardPool = {
    chestRarity: (Nat, Nat);
    flux: (Nat, Nat);
    shards: (Nat, Nat);
  };

  // Matchmaking
  public type MMInfo = {
    id: PlayerId;
    matchAccepted: Bool;
    elo: Float;
    playerGameData: Text;
    lastPlayerActive: Nat64;
    username: Username;
  };

  public type MMStatus = {
    #Searching;
    #Reserved;
    #Accepting;
    #Accepted;
    #InGame;
    #Ended;
  };

  public type MMSearchStatus = {
    #Assigned;
    #Available;
    #NotAvailable;
  };

  public type MMPlayerStatus = {
    status: MMStatus;
    matchID: MatchID;
  };

  public type MatchData = {
    matchID: MatchID;
    player1: MMInfo;
    player2: ?MMInfo;
    status: MMStatus;
  };

  public type FullMatchData = {
    matchID: MatchID;
    player1: {
      id: PlayerId;
      username: Username;
      avatar: AvatarID;
      level: Level;
      matchAccepted: Bool;
      elo: Float;
      playerGameData: Text;
    };
    player2: ?{
      id: PlayerId;
      username: Username;
      avatar: AvatarID;
      level: Level;
      matchAccepted: Bool;
      elo: Float;
      playerGameData: Text;
    };
    status: MMStatus;
  };

  // Match History
  public type MatchOpt = {
    #Ranked;
    #Normal;
    #Tournament;
  };

  public type PlayerRecord = {
    playerId: Principal;
    faction: PlayerFaction;
  };

  public type MatchRecord = {
    matchID: MatchID;
    map: MatchMap;
    team1: [PlayerRecord];
    team2: [PlayerRecord];
    faction1: [PlayerFaction];
    faction2: [PlayerFaction];
    result: MatchResult;
    timestamp: Time.Time;
    mode: MatchOpt;
  };
}
