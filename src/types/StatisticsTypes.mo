module {
  public type GameID = Nat;
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
    // averageGamesWithFaction   : [GamesWithFaction];
    // averageGamesGameMode      : [GamesWithGameMode];
    // averageGamesWithCharacter : [GamesWithCharacter];
  };

};
