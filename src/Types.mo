import Time "mo:base/Time";

module {
  // General Types
  public type PlayerId = Principal;
  public type Username = Text;
  public type AvatarID = Nat;
  public type Description = Text;
  public type RegistrationDate = Time.Time;
  public type Level = Nat;
  public type MatchID = Nat;
  public type TokenId = Nat;

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

  public type PlayerStats = {
    playerId: PlayerId;
    energyUsed: Float;
    energyGenerated: Float;
    energyWasted: Float;
    energyChargeRate: Float;
    xpEarned: Float;
    damageDealt: Float;
    damageTaken: Float;
    damageCritic: Float;
    damageEvaded: Float;
    kills: Float;
    deploys: Float;
    secRemaining: Float;
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
    energyGenerated: Float;
    energyUsed: Float;
    energyWasted: Float;
    totalDamageDealt: Float;
    totalDamageTaken: Float;
    totalDamageCrit: Float;
    totalDamageEvaded: Float;
    totalXpEarned: Float;
    totalGamesWithFaction: [GamesWithFaction];
    totalGamesGameMode: [GamesWithGameMode];
    totalGamesWithCharacter: [GamesWithCharacter];
  };

  public type AverageStats = {
    averageEnergyGenerated: Float;
    averageEnergyUsed: Float;
    averageEnergyWasted: Float;
    averageDamageDealt: Float;
    averageKills: Float;
    averageXpEarned: Float;
  };

  public type OverallStats = {
    totalGamesPlayed: Nat;
    totalGamesSP: Nat;
    totalGamesMP: Nat;
    totalDamageDealt: Float;
    totalTimePlayed: Float;
    totalKills: Float;
    totalEnergyGenerated: Float;
    totalEnergyUsed: Float;
    totalEnergyWasted: Float;
    totalXpEarned: Float;
    totalGamesWithFaction: [OverallGamesWithFaction];
    totalGamesGameMode: [OverallGamesWithGameMode];
    totalGamesWithCharacter: [OverallGamesWithCharacter];
  };

  // Missions
  public type MissionType = {
    #GamesCompleted;
    #GamesWon;
    #LevelReached;
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
    total: Float;
  };

  public type MissionsUser = {
    id_mission: Nat;
    total: Float;
    progress: Float;
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
    progress: Float;
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
       // faction: Faction;
    };
    player2: ?{
        id: PlayerId;
        username: Username;
        avatar: AvatarID;
        level: Level;
        matchAccepted: Bool;
        elo: Float;
        playerGameData: Text;
        //faction: Faction;
    };
    status: MMStatus;
};

  // Match History
  public type MatchOpt = { #Ranked; #Normal; #Tournament };

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
