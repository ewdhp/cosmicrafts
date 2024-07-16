import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Int64 "mo:base/Int64";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Types "Types";
import Utils "Utils";

shared actor class Cosmicrafts() {

  private stable var _cosmicraftsPrincipal : Principal = Principal.fromText("ajuq4-ruaaa-aaaaa-qaaga-cai");

  // Types
  public type PlayerId = Types.PlayerId;
  public type Username = Types.Username;
  public type AvatarID = Types.AvatarID;
  public type Description = Types.Description;
  public type RegistrationDate = Types.RegistrationDate;
  public type Level = Types.Level;
  public type MatchID = Types.MatchID;

  public type FriendDetails = Types.FriendDetails;
  public type Player = Types.Player;

  public type GamesWithFaction = Types.GamesWithFaction;
  public type GamesWithGameMode = Types.GamesWithGameMode;
  public type GamesWithCharacter = Types.GamesWithCharacter;
  public type BasicStats = Types.BasicStats;
  public type PlayerStats = Types.PlayerStats;
  public type PlayerGamesStats = Types.PlayerGamesStats;
  public type OverallStats = Types.OverallStats;
  public type AverageStats = Types.AverageStats;

  public type MMInfo = Types.MMInfo;
  public type MMSearchStatus = Types.MMSearchStatus;
  public type MMStatus = Types.MMStatus;
  public type MMPlayerStatus = Types.MMPlayerStatus;
  public type MatchData = Types.MatchData;
  public type FullMatchData = Types.FullMatchData;

  public type RewardType = Types.RewardType;
  public type PrizeType = Types.PrizeType;
  public type Reward = Types.Reward;
  public type RewardsUser = Types.RewardsUser;
  public type RewardProgress = Types.RewardProgress;

  // Utils
  func _natEqual(a : Nat, b : Nat) : Bool {
    return a == b;
  };

  func _natHash(a: Nat): Hash.Hash {
    return Utils._natHash(a);
  };

  // Players
  private stable var _players : [(PlayerId, Player)] = [];
  var players : HashMap.HashMap<PlayerId, Player> = HashMap.fromIter(_players.vals(), 0, Principal.equal, Principal.hash);

  public shared ({ caller : PlayerId }) func registerPlayer(username : Username, avatar : AvatarID) : async (Bool, PlayerId) {
    let PlayerId = caller;
    switch (players.get(PlayerId)) {
        case (null) {
            let registrationDate = Time.now();
            let initialStats: PlayerGamesStats = {
                gamesPlayed = 0;
                gamesWon = 0;
                gamesLost = 0;
                energyGenerated = 0;
                energyUsed = 0;
                energyWasted = 0;
                totalDamageDealt = 0;
                totalDamageTaken = 0;
                totalDamageCrit = 0;
                totalDamageEvaded = 0;
                totalXpEarned = 0;
                totalGamesWithFaction = [];
                totalGamesGameMode = [];
                totalGamesWithCharacter = [];
            };
            let initialAverageStats: AverageStats = {
                averageEnergyGenerated = 0;
                averageEnergyUsed = 0;
                averageEnergyWasted = 0;
                averageDamageDealt = 0;
                averageKills = 0;
                averageXpEarned = 0;
            };
            let newPlayer : Player = {
                id = PlayerId;
                username = username;
                avatar = avatar;
                description = "";
                registrationDate = registrationDate;
                level = 0;
                elo = 1200;
                friends = [];
                stats = initialStats;
                averageStats = initialAverageStats;
            };
            players.put(PlayerId, newPlayer);
            return (true, PlayerId);
        };
        case (?_) {
            return (false, PlayerId); // User already exists
        };
    };
};

  public shared ({ caller : PlayerId }) func updateUsername(username : Username) : async (Bool, PlayerId) {
    let PlayerId = caller;
    switch (players.get(PlayerId)) {
        case (null) {
            return (false, PlayerId); // User record does not exist
        };
        case (?player) {
            let updatedPlayer : Player = {
                id = player.id;
                username = username;
                avatar = player.avatar;
                description = player.description;
                registrationDate = player.registrationDate;
                level = player.level;
                elo = player.elo;
                friends = player.friends;
                stats = player.stats;
                averageStats = player.averageStats;
            };
            players.put(PlayerId, updatedPlayer);
            return (true, PlayerId);
        };
    };
};

public shared ({ caller : PlayerId }) func updateAvatar(avatar : AvatarID) : async (Bool, PlayerId) {
    let PlayerId = caller;
    switch (players.get(PlayerId)) {
        case (null) {
            return (false, PlayerId);
        };
        case (?player) {
            let updatedPlayer : Player = {
                id = player.id;
                username = player.username;
                avatar = avatar;
                description = player.description;
                registrationDate = player.registrationDate;
                level = player.level;
                elo = player.elo;
                friends = player.friends;
                stats = player.stats;
                averageStats = player.averageStats;
            };
            players.put(PlayerId, updatedPlayer);
            return (true, PlayerId);
        };
    };
};

public shared ({ caller : PlayerId }) func updateDescription(description : Description) : async (Bool, PlayerId) {
    let PlayerId = caller;
    switch (players.get(PlayerId)) {
        case (null) {
            return (false, PlayerId); // User record does not exist
        };
        case (?player) {
            let updatedPlayer : Player = {
                id = player.id;
                username = player.username;
                avatar = player.avatar;
                description = description;
                registrationDate = player.registrationDate;
                level = player.level;
                elo = player.elo;
                friends = player.friends;
                stats = player.stats;
                averageStats = player.averageStats;
            };
            players.put(PlayerId, updatedPlayer);
            return (true, PlayerId);
        };
    };
};

public shared ({ caller: PlayerId }) func addFriend(friendId: PlayerId) : async (Bool, Text) {
    let playerId = caller;
    switch (players.get(playerId)) {
        case (null) {
            return (false, "User record does not exist"); // User record does not exist
        };
        case (?player) {
            switch (players.get(friendId)) {
                case (null) {
                    return (false, "Friend principal not registered"); // Friend principal not registered
                };
                case (?friend) {
                    let updatedFriends = Buffer.Buffer<FriendDetails>(player.friends.size() + 1);
                    for (friendDetail in player.friends.vals()) {
                        updatedFriends.add(friendDetail);
                    };
                    updatedFriends.add({
                        playerId = friendId;
                        username = friend.username;
                        avatar = friend.avatar;
                    });
                    let updatedPlayer: Player = {
                        id = player.id;
                        username = player.username;
                        avatar = player.avatar;
                        description = player.description;
                        registrationDate = player.registrationDate;
                        level = player.level;
                        elo = player.elo;
                        friends = Buffer.toArray(updatedFriends);
                        stats = player.stats;
                        averageStats = player.averageStats;
                    };
                    players.put(playerId, updatedPlayer);
                    return (true, "Friend added successfully");
                };
            };
        };
    };
};

  public query func getUserDetails(player : PlayerId) : async ?Player {
    return players.get(player);
  };

  public query func searchUserByUsername(username : Username) : async [Player] {
    let result : Buffer.Buffer<Player> = Buffer.Buffer<Player>(0);
    for ((_, userRecord) in players.entries()) {
      if (userRecord.username == username) {
        result.add(userRecord);
      };
    };
    return Buffer.toArray(result);
  };

  public query func searchUserByPrincipal(PlayerId : PlayerId) : async ?Player {
    return players.get(PlayerId);
  };

  public query ({ caller: PlayerId }) func getFriendsList() : async ?[PlayerId] {
    switch (players.get(caller)) {
        case (null) {
            return null; // User record does not exist
        };
        case (?player) {
            let friendIds = Array.map<FriendDetails, PlayerId>(player.friends, func (friend: FriendDetails): PlayerId {
                return friend.playerId;
            });
            return ?friendIds;
        };
    };
};

  // Player Data
  public shared (msg) func getPlayer() : async ?Player {
    return players.get(msg.caller);
  };

  public composite query func getPlayerData(player : Principal) : async ?Player {
    return players.get(player);
  };

  public shared query (msg) func getMyPlayerData() : async ?Player {
    return players.get(msg.caller);
  };

  public query func getAllPlayers() : async [Player] {
    return Iter.toArray(players.vals());
  };

  public query func getPlayerElo(player : Principal) : async Float {
    return switch (players.get(player)) {
      case (null) {
        1200;
      };
      case (?player) {
        player.elo;
      };
    };
  };

public shared func updatePlayerElo(playerId : Principal, newELO : Float) : async Bool {
    // assert (msg.caller == _statisticPrincipal); /// Only Statistics Canister can update ELO, change for statistics principal later
    switch (players.get(playerId)) {
        case (null) {
            return false;
        };
        case (?existingPlayer) {
            let updatedPlayer : Player = {
                id = existingPlayer.id;
                username = existingPlayer.username;
                avatar = existingPlayer.avatar;
                description = existingPlayer.description;
                registrationDate = existingPlayer.registrationDate;
                level = existingPlayer.level;
                elo = newELO;
                friends = existingPlayer.friends;
                stats = existingPlayer.stats;
                averageStats = existingPlayer.averageStats;
            };
            players.put(playerId, updatedPlayer);
            return true;
        };
    };
};

  // Statistics
  private stable var k : Int = 30;
  private stable var _basicStats: [(MatchID, BasicStats)] = [];
  var basicStats: HashMap.HashMap<MatchID, BasicStats> = HashMap.fromIter(_basicStats.vals(), 0, _natEqual, _natHash);

  private stable var _playerGamesStats: [(PlayerId, PlayerGamesStats)] = [];
  var playerGamesStats: HashMap.HashMap<PlayerId, PlayerGamesStats> = HashMap.fromIter(_playerGamesStats.vals(), 0, Principal.equal, Principal.hash);

  private stable var _onValidation: [(MatchID, BasicStats)] = [];
  var onValidation: HashMap.HashMap<MatchID, BasicStats> = HashMap.fromIter(_onValidation.vals(), 0, _natEqual, _natHash);

  private stable var overallStats: OverallStats = {
      totalGamesPlayed: Nat = 0;
      totalGamesSP: Nat = 0;
      totalGamesMP: Nat = 0;
      totalDamageDealt: Float = 0;
      totalTimePlayed: Float = 0;
      totalKills: Float = 0;
      totalEnergyGenerated: Float = 0;
      totalEnergyUsed: Float = 0;
      totalEnergyWasted: Float = 0;
      totalXpEarned: Float = 0;
      totalGamesWithFaction: [GamesWithFaction] = [];
      totalGamesGameMode: [GamesWithGameMode] = [];
      totalGamesWithCharacter: [GamesWithCharacter] = [];
  };

  private func _initializeNewPlayerStats(_player: Principal): async (Bool, Text) {
      let _playerStats: PlayerGamesStats = {
          gamesPlayed = 0;
          gamesWon = 0;
          gamesLost = 0;
          energyGenerated = 0;
          energyUsed = 0;
          energyWasted = 0;
          totalDamageDealt = 0;
          totalDamageTaken = 0;
          totalDamageCrit = 0;
          totalDamageEvaded = 0;
          totalXpEarned = 0;
          totalGamesWithFaction = [];
          totalGamesGameMode = [];
          totalGamesWithCharacter = [];
      };
      playerGamesStats.put(_player, _playerStats);
      return (true, "Player stats initialized");
  };


  private func updatePlayerELO(PlayerId : PlayerId, won : Nat, otherPlayerId : ?PlayerId) : async Bool {
    switch (otherPlayerId) {
      case (null) {
        return false;
      };
      case (?otherPlayer) {
        // Get both player's ELO
        var _p1Elo : Float = await getPlayerElo(PlayerId);
        let _p2Elo : Float = await getPlayerElo(otherPlayer);
        // Calculate expected results
        let _p1Expected : Float = 1 / (1 + Float.pow(10, (_p2Elo - _p1Elo) / 400));
        let _p2Expected : Float = 1 / (1 + Float.pow(10, (_p1Elo - _p2Elo) / 400));
        // Update ELO
        let _elo : Float = _p1Elo + Float.fromInt(k) * (Float.fromInt64(Int64.fromInt(won)) - _p1Expected);
        let _updated = await updatePlayerElo(PlayerId, _elo);
        return true;
      };
    };
  };

  public shared (msg) func setGameOver(caller : Principal) : async (Bool, Bool, ?Principal) {
    assert (msg.caller == Principal.fromText("ajuq4-ruaaa-aaaaa-qaaga-cai")); // main canisterID
    switch (playerStatus.get(caller)) {
      case (null) {
        return (false, false, null);
      };
      case (?status) {
        switch (inProgress.get(status.matchID)) {
          case (null) {
            switch (searching.get(status.matchID)) {
              case (null) {
                switch (finishedGames.get(status.matchID)) {
                  case (null) {
                    return (false, false, null);
                  };
                  case (?match) {
                    // Game is not on the searching or in-progress list, so we just remove the status from the player
                    playerStatus.delete(caller);
                    return (true, caller == match.player1.id, getOtherPlayer(match, caller));
                  };
                };
              };
              case (?match) {
                // Game is on Searching list, so we remove it, add it to the finished list and remove the status from the player
                finishedGames.put(status.matchID, match);
                searching.delete(status.matchID);
                playerStatus.delete(caller);
                return (true, caller == match.player1.id, getOtherPlayer(match, caller));
              };
            };
          };
          case (?match) {
            // Game is on in-progress list, so we remove it, add it to the finished list and remove the status from the player
            finishedGames.put(status.matchID, match);
            inProgress.delete(status.matchID);
            playerStatus.delete(caller);
            return (true, caller == match.player1.id, getOtherPlayer(match, caller));
          };
        };
      };
    };
  };

public shared(msg) func saveFinishedGame(matchID: MatchID, _playerStats: PlayerStats) : async (Bool, Text) {
    var _txt: Text = "";

    // Check if the match exists in basicStats
    let isExistingMatch = switch (basicStats.get(matchID)) {
        case (null) { false };
        case (?_) { true };
    };
    
    // Set the game as over
    let endingGame: (Bool, Bool, ?Principal) = await setGameOver(msg.caller);

    if (not isExistingMatch) {
        // Save the basic stats for a new match
        let newBasicStats: BasicStats = {
            playerStats = [_playerStats];
        };
        basicStats.put(matchID, newBasicStats);

        // Validate the game
        let (_gameValid, validationMsg) = validateGame(300.0 - _playerStats.secRemaining, _playerStats.xpEarned);
        if (not _gameValid) {
            onValidation.put(matchID, newBasicStats);
            return (false, validationMsg);
        };

        // Update player stats
        let _winner = if (_playerStats.wonGame) 1 else 0;
        let _looser = if (not _playerStats.wonGame) 1 else 0;
        let _elo: Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);
        var _progressRewards: [RewardProgress] = [{
            rewardType = #GamesCompleted;
            progress = 1;
        }];
        if (_playerStats.wonGame) {
            let _wonProgress: RewardProgress = {
                rewardType = #GamesWon;
                progress = 1;
            };
            _progressRewards := Array.append(_progressRewards, [_wonProgress]);
        };
        let _progressAdded = await addProgressToRewards(msg.caller, _progressRewards);
        _txt := _progressAdded.1;

        // Update or create player game stats
        updatePlayerGameStats(msg.caller, _playerStats, _winner, _looser);

        // Update overall stats
        updateOverallStats(_playerStats, _winner);

        return (true, "Game saved");
    } else {
        // If the match was already saved, add the new player's stats
        switch (basicStats.get(matchID)) {
            case (null) {
                return (false, "Unexpected error: Match not found");
            };
            case (?_bs) {
                let updatedPlayerStats = Array.append(_bs.playerStats, [_playerStats]);
                let updatedBasicStats: BasicStats = { playerStats = updatedPlayerStats };
                basicStats.put(matchID, updatedBasicStats);

                // Validate the game
                let (_gameValid, validationMsg) = validateGame(300.0 - _playerStats.secRemaining, _playerStats.xpEarned);
                if (not _gameValid) {
                    onValidation.put(matchID, updatedBasicStats);
                    return (false, validationMsg);
                };

                // Update player stats
                let _winner = if (_playerStats.wonGame) 1 else 0;
                let _looser = if (not _playerStats.wonGame) 1 else 0;
                let _elo: Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);
                var _progressRewards: [RewardProgress] = [{
                    rewardType = #GamesCompleted;
                    progress = 1;
                }];
                if (_playerStats.wonGame) {
                    let _wonProgress: RewardProgress = {
                        rewardType = #GamesWon;
                        progress = 1;
                    };
                    _progressRewards := Array.append(_progressRewards, [_wonProgress]);
                };
                let _progressAdded = await addProgressToRewards(msg.caller, _progressRewards);
                _txt := _progressAdded.1;

                // Update or create player game stats
                updatePlayerGameStats(msg.caller, _playerStats, _winner, _looser);

                // Update overall stats
                updateOverallStats(_playerStats, _winner);

                return (true, _txt # " - Game saved");
            };
        };
    };
};


  // Helper function to update player game stats
private func updatePlayerGameStats(playerId: PlayerId, _playerStats: PlayerStats, _winner: Nat, _looser: Nat) {
    switch (playerGamesStats.get(playerId)) {
        case (null) {
            let _gs: PlayerGamesStats = {
                gamesPlayed = 1;
                gamesWon = _winner;
                gamesLost = _looser;
                energyGenerated = _playerStats.energyGenerated;
                energyUsed = _playerStats.energyUsed;
                energyWasted = _playerStats.energyWasted;
                totalDamageDealt = _playerStats.damageDealt;
                totalDamageTaken = _playerStats.damageTaken;
                totalDamageCrit = _playerStats.damageCritic;
                totalDamageEvaded = _playerStats.damageEvaded;
                totalXpEarned = _playerStats.xpEarned;
                totalGamesWithFaction = [{factionID = _playerStats.faction; gamesPlayed = 1; gamesWon = _winner;}];
                totalGamesGameMode = [{gameModeID = _playerStats.gameMode; gamesPlayed = 1; gamesWon = _winner;}];
                totalGamesWithCharacter = [{characterID = _playerStats.characterID; gamesPlayed = 1; gamesWon = _winner;}];
            };
            playerGamesStats.put(playerId, _gs);
        };
        case (?_bs) {
            var _gamesWithFaction: [GamesWithFaction] = [];
            var _gamesWithGameMode: [GamesWithGameMode] = [];
            var _totalGamesWithCharacter: [GamesWithCharacter] = [];
            for (gf in _bs.totalGamesWithFaction.vals()) {
                if (gf.factionID == _playerStats.faction) {
                    _gamesWithFaction := Array.append(_gamesWithFaction, [{gamesPlayed = gf.gamesPlayed + 1; factionID = gf.factionID; gamesWon = gf.gamesWon + _winner;}]);
                } else {
                    _gamesWithFaction := Array.append(_gamesWithFaction, [gf]);
                };
            };
            for (gm in _bs.totalGamesGameMode.vals()) {
                if (gm.gameModeID == _playerStats.gameMode) {
                    _gamesWithGameMode := Array.append(_gamesWithGameMode, [{gamesPlayed = gm.gamesPlayed + 1; gameModeID = gm.gameModeID; gamesWon = gm.gamesWon + _winner;}]);
                } else {
                    _gamesWithGameMode := Array.append(_gamesWithGameMode, [gm]);
                };
            };
            for (gc in _bs.totalGamesWithCharacter.vals()) {
                if (gc.characterID == _playerStats.characterID) {
                    _totalGamesWithCharacter := Array.append(_totalGamesWithCharacter, [{gamesPlayed = gc.gamesPlayed + 1; characterID = gc.characterID; gamesWon = gc.gamesWon + _winner;}]);
                } else {
                    _totalGamesWithCharacter := Array.append(_totalGamesWithCharacter, [gc]);
                };
            };
            var _thisGameXP = _playerStats.xpEarned;
            if (_playerStats.wonGame) {
                _thisGameXP := _thisGameXP * 2;
            } else {
                _thisGameXP := _thisGameXP * 0.5;
            };
            if (_playerStats.gameMode == 1) {
                _thisGameXP := _thisGameXP * 2;
            } else {
                _thisGameXP := _thisGameXP * 0.25;
            };
            let _gs: PlayerGamesStats = {
                gamesPlayed = _bs.gamesPlayed + 1;
                gamesWon = _bs.gamesWon + _winner;
                gamesLost = _bs.gamesLost + _looser;
                energyGenerated = _bs.energyGenerated + _playerStats.energyGenerated;
                energyUsed = _bs.energyUsed + _playerStats.energyUsed;
                energyWasted = _bs.energyWasted + _playerStats.energyWasted;
                totalDamageDealt = _bs.totalDamageDealt + _playerStats.damageDealt;
                totalDamageTaken = _bs.totalDamageTaken + _playerStats.damageTaken;
                totalDamageCrit = _bs.totalDamageCrit + _playerStats.damageCritic;
                totalDamageEvaded = _bs.totalDamageEvaded + _playerStats.damageEvaded;
                totalXpEarned = _bs.totalXpEarned + _thisGameXP;
                totalGamesWithFaction = _gamesWithFaction;
                totalGamesGameMode = _gamesWithGameMode;
                totalGamesWithCharacter = _totalGamesWithCharacter;
            };
            playerGamesStats.put(playerId, _gs);
        };
    };
};

  // Helper function to update overall stats
  private func updateOverallStats(_playerStats: PlayerStats, _winner: Nat) {
      var _totalGamesWithFaction: [GamesWithFaction] = [];
      var _totalGamesWithGameMode: [GamesWithGameMode] = [];
      var _totalGamesWithCharacter: [GamesWithCharacter] = [];
      for (gf in overallStats.totalGamesWithFaction.vals()) {
          if (gf.factionID == _playerStats.faction) {
              _totalGamesWithFaction := Array.append(_totalGamesWithFaction, [{gamesPlayed = gf.gamesPlayed + 1; factionID = gf.factionID; gamesWon = gf.gamesWon + _winner;}]);
          } else {
              _totalGamesWithFaction := Array.append(_totalGamesWithFaction, [gf]);
          };
      };
      for (gm in overallStats.totalGamesGameMode.vals()) {
          if (gm.gameModeID == _playerStats.gameMode) {
              _totalGamesWithGameMode := Array.append(_totalGamesWithGameMode, [{gamesPlayed = gm.gamesPlayed + 1; gameModeID = gm.gameModeID; gamesWon = gm.gamesWon + _winner;}]);
          } else {
              _totalGamesWithGameMode := Array.append(_totalGamesWithGameMode, [gm]);
          };
      };
      for (gc in overallStats.totalGamesWithCharacter.vals()) {
          if (gc.characterID == _playerStats.characterID) {
              _totalGamesWithCharacter := Array.append(_totalGamesWithCharacter, [{gamesPlayed = gc.gamesPlayed + 1; characterID = gc.characterID; gamesWon = gc.gamesWon + _winner;}]);
          } else {
              _totalGamesWithCharacter := Array.append(_totalGamesWithCharacter, [gc]);
          };
      };
      let _os: OverallStats = {
          totalGamesPlayed = overallStats.totalGamesPlayed + 1;
          totalGamesSP = if (_playerStats.gameMode == 2) overallStats.totalGamesSP + 1 else overallStats.totalGamesSP;
          totalGamesMP = if (_playerStats.gameMode == 1) overallStats.totalGamesMP + 1 else overallStats.totalGamesMP;
          totalDamageDealt = overallStats.totalDamageDealt + _playerStats.damageDealt;
          totalTimePlayed = overallStats.totalTimePlayed;
          totalKills = overallStats.totalKills + _playerStats.kills;
          totalEnergyUsed = overallStats.totalEnergyUsed + _playerStats.energyUsed;
          totalEnergyGenerated = overallStats.totalEnergyGenerated + _playerStats.energyGenerated;
          totalEnergyWasted = overallStats.totalEnergyWasted + _playerStats.energyWasted;
          totalGamesWithFaction = _totalGamesWithFaction;
          totalGamesGameMode = overallStats.totalGamesGameMode;
          totalGamesWithCharacter = _totalGamesWithCharacter;
          totalXpEarned = overallStats.totalXpEarned + _playerStats.xpEarned;
      };
      overallStats := _os;
  };

// Validator
private func validateGame(timeInSeconds: Float, score: Float) : (Bool, Text) {
    let maxScoreRate: Float = 550000.0 / (5.0 * 60.0);
    let maxPlausibleScore: Float = maxScoreRate * timeInSeconds;
    let isScoreValid: Bool = score <= maxPlausibleScore;

    if (isScoreValid) {
        return (true, "Game is valid");
    } else {
        return (false, "Score is not valid");
    }
};

  public query func getOverallStats() : async OverallStats {
    return overallStats;
  };

  public query func getAverageStats() : async AverageStats {
    let _averageStats : AverageStats = {
      averageEnergyGenerated = overallStats.totalEnergyGenerated / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(overallStats.totalGamesPlayed)));
      averageEnergyUsed = overallStats.totalEnergyUsed / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(overallStats.totalGamesPlayed)));
      averageEnergyWasted = overallStats.totalEnergyWasted / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(overallStats.totalGamesPlayed)));
      averageDamageDealt = overallStats.totalDamageDealt / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(overallStats.totalGamesPlayed)));
      averageKills = overallStats.totalKills / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(overallStats.totalGamesPlayed)));
      averageXpEarned = overallStats.totalXpEarned / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(overallStats.totalGamesPlayed)));
    };
    return _averageStats;
  };

  public shared query (msg) func getMyStats() : async ?PlayerGamesStats {
    switch (playerGamesStats.get(msg.caller)) {
      case (null) {
        let _playerStats : PlayerGamesStats = {
          gamesPlayed = 0;
          gamesWon = 0;
          gamesLost = 0;
          energyGenerated = 0;
          energyUsed = 0;
          energyWasted = 0;
          totalDamageDealt = 0;
          totalDamageTaken = 0;
          totalDamageCrit = 0;
          totalDamageEvaded = 0;
          totalXpEarned = 0;
          totalGamesWithFaction = [];
          totalGamesGameMode = [];
          totalGamesWithCharacter = [];
        };
        return ?_playerStats;
      };
      case (?_p) {
        return playerGamesStats.get(msg.caller);
      };
    };
  };

  public shared query (msg) func getMyAverageStats() : async ?AverageStats {
    switch (playerGamesStats.get(msg.caller)) {
      case (null) {
        let _newAverageStats : AverageStats = {
          averageEnergyGenerated = 0;
          averageEnergyUsed = 0;
          averageEnergyWasted = 0;
          averageDamageDealt = 0;
          averageKills = 0;
          averageXpEarned = 0;
        };
        return ?_newAverageStats;
      };
      case (?_p) {
        let _averageStats : AverageStats = {
          averageEnergyGenerated = _p.energyGenerated / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageEnergyUsed = _p.energyUsed / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageEnergyWasted = _p.energyWasted / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageDamageDealt = _p.totalDamageDealt / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageKills = _p.totalDamageDealt / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageXpEarned = _p.totalXpEarned / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
        };
        return ?_averageStats;
      };
    };
  };

  public shared query func getBasicStats(MatchID : MatchID) : async ?BasicStats {
    return basicStats.get(MatchID);
  };

  public query func getPlayerStats(_player : Principal) : async ?PlayerGamesStats {
    switch (playerGamesStats.get(_player)) {
      case (null) {
        let _playerStats : PlayerGamesStats = {
          gamesPlayed = 0;
          gamesWon = 0;
          gamesLost = 0;
          energyGenerated = 0;
          energyUsed = 0;
          energyWasted = 0;
          totalDamageDealt = 0;
          totalDamageTaken = 0;
          totalDamageCrit = 0;
          totalDamageEvaded = 0;
          totalXpEarned = 0;
          totalGamesWithFaction = [];
          totalGamesGameMode = [];
          totalGamesWithCharacter = [];
        };
        return ?_playerStats;
      };
      case (?_p) {
        return playerGamesStats.get(_player);
      };
    };
    return playerGamesStats.get(_player);
  };

  public query func getPlayerAverageStats(_player : Principal) : async ?AverageStats {
    switch (playerGamesStats.get(_player)) {
      case (null) {
        let _newAverageStats : AverageStats = {
          averageEnergyGenerated = 0;
          averageEnergyUsed = 0;
          averageEnergyWasted = 0;
          averageDamageDealt = 0;
          averageKills = 0;
          averageXpEarned = 0;
        };
        return ?_newAverageStats;
      };
      case (?_p) {
        let _averageStats : AverageStats = {
          averageEnergyGenerated = _p.energyGenerated / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageEnergyUsed = _p.energyUsed / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageEnergyWasted = _p.energyWasted / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageDamageDealt = _p.totalDamageDealt / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageKills = _p.totalDamageDealt / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
          averageXpEarned = _p.totalXpEarned / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(_p.gamesPlayed)));
        };
        return ?_averageStats;
      };
    };
  };

  //MatchMaking
  private var ONE_SECOND : Nat64 = 1_000_000_000;
  private stable var _matchID : Nat = 1;
  private var inactiveSeconds : Nat64 = 30 * ONE_SECOND;

  private stable var _searching : [(MatchID, MatchData)] = [];
  var searching : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_searching.vals(), 0, _natEqual, _natHash);

  private stable var _playerStatus : [(PlayerId, MMPlayerStatus)] = [];
  var playerStatus : HashMap.HashMap<PlayerId, MMPlayerStatus> = HashMap.fromIter(_playerStatus.vals(), 0, Principal.equal, Principal.hash);

  private stable var _inProgress : [(MatchID, MatchData)] = [];
  var inProgress : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_inProgress.vals(), 0, _natEqual, _natHash);

  private stable var _finishedGames : [(MatchID, MatchData)] = [];
  var finishedGames : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_finishedGames.vals(), 0, _natEqual, _natHash);

  // query de finished games por principal ID aparte de MatchID
public query func getMatchIDsByPrincipal(player: PlayerId): async [MatchID] {
    let buffer = Buffer.Buffer<MatchID>(0);
    for ((matchID, matchData) in finishedGames.entries()) {
        if (matchData.player1.id == player) {
            buffer.add(matchID);
        } else {
            switch (matchData.player2) {
                case (null) {};
                case (?p2) {
                    if (p2.id == player) {
                        buffer.add(matchID);
                    }
                };
            }
        }
    };
    return Buffer.toArray(buffer);
};

  public shared (msg) func setPlayerActive() : async Bool {
    assert (Principal.notEqual(msg.caller, NULL_PRINCIPAL));
    assert (Principal.notEqual(msg.caller, ANON_PRINCIPAL));

    switch (playerStatus.get(msg.caller)) {
        case (null) { return false };
        case (?_ps) {
            switch (searching.get(_ps.matchID)) {
                case (null) { return false };
                case (?_m) {
                    let _now = Nat64.fromIntWrap(Time.now());
                    if (_m.player1.id == msg.caller) {
                        if ((_m.player1.lastPlayerActive + inactiveSeconds) < _now) {
                            return false;
                        };
                        let _p : MMInfo = _m.player1;
                        let _p1 : MMInfo = structPlayerActiveNow(_p);
                        let _gameData : MatchData = structMatchData(_p1, _m.player2, _m);
                        searching.put(_m.matchID, _gameData);
                        return true;
                    } else {
                        let _p : MMInfo = switch (_m.player2) {
                            case (null) { return false };
                            case (?_p) { _p };
                        };
                        if ((_p.lastPlayerActive + inactiveSeconds) < _now) {
                            return false;
                        };
                        let _p2 : MMInfo = structPlayerActiveNow(_p);
                        let _gameData : MatchData = structMatchData(_m.player1, ?_p2, _m);
                        searching.put(_m.matchID, _gameData);
                        return true;
                    };
                };
            };
            return false;
        };
    };
};

private func structPlayerActiveNow(_p1 : MMInfo) : MMInfo {
    let _p : MMInfo = {
        id = _p1.id;
        elo = _p1.elo;
        matchAccepted = _p1.matchAccepted;
        playerGameData = _p1.playerGameData;
        lastPlayerActive = Nat64.fromIntWrap(Time.now());
        username = _p1.username; // Use existing type
    };
    return _p;
};

private func structMatchData(_p1 : MMInfo, _p2 : ?MMInfo, _m : MatchData) : MatchData {
    let _md : MatchData = {
        matchID = _m.matchID;
        player1 = _p1;
        player2 = _p2;
        status = _m.status;
    };
    return _md;
};

  private func activatePlayerSearching(player : Principal, matchID : Nat) : Bool {
    switch (searching.get(matchID)) {
      case (null) { return false };
      case (?_m) {
        if (_m.status != #Searching) {
          return false;
        };
        let _now = Nat64.fromIntWrap(Time.now());
        if (_m.player1.id == player) {
          /// Check if the time of expiration have passed already and return false
          if ((_m.player1.lastPlayerActive + inactiveSeconds) < _now) {
            return false;
          };
          let _p : MMInfo = _m.player1;
          let _p1 : MMInfo = structPlayerActiveNow(_p);
          let _gameData : MatchData = structMatchData(_p1, _m.player2, _m);
          searching.put(_m.matchID, _gameData);
          return true;
        } else {
          let _p : MMInfo = switch (_m.player2) {
            case (null) { return false };
            case (?_p) { _p };
          };
          if (player != _p.id) {
            return false;
          };
          if ((_p.lastPlayerActive + inactiveSeconds) < _now) {
            return false;
          };
          let _p2 : MMInfo = structPlayerActiveNow(_p);
          let _gameData : MatchData = structMatchData(_m.player1, ?_p2, _m);
          searching.put(_m.matchID, _gameData);
          return true;
        };
      };
    };
  };

  func _floatSort(a : Float, b : Float) : Float {
    if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    } else {
      return 0;
    };
  };

  public shared (msg) func getMatchSearching(pgd : Text) : async (MMSearchStatus, Nat, Text) {
    assert (Principal.notEqual(msg.caller, NULL_PRINCIPAL));
    assert (Principal.notEqual(msg.caller, ANON_PRINCIPAL));
    let _now : Nat64 = Nat64.fromIntWrap(Time.now());
    let _pELO : Float = await getPlayerElo(msg.caller);
    var _gamesByELO : [MatchData] = Iter.toArray(searching.vals());
    for (m in _gamesByELO.vals()) {
        if (m.player2 == null and Principal.notEqual(m.player1.id, msg.caller) and (m.player1.lastPlayerActive + inactiveSeconds) > _now) {
            let username = switch (await getUserDetails(msg.caller)) {
                case (null) { "" };
                case (?player) { player.username };
            };
            let _p2 : MMInfo = {
                id = msg.caller;
                elo = _pELO;
                matchAccepted = true;
                playerGameData = pgd;
                lastPlayerActive = Nat64.fromIntWrap(Time.now());
                username = username;
            };
            let _p1 : MMInfo = {
                id = m.player1.id;
                elo = m.player1.elo;
                matchAccepted = true;
                playerGameData = m.player1.playerGameData;
                lastPlayerActive = m.player1.lastPlayerActive;
                username = m.player1.username;
            };
            let _gameData : MatchData = {
                matchID = m.matchID;
                player1 = _p1;
                player2 = ?_p2;
                status = #Accepted;
            };
            let _p_s : MMPlayerStatus = {
                status = #Accepted;
                matchID = m.matchID;
            };
            inProgress.put(m.matchID, _gameData);
            let _removedSearching = searching.remove(m.matchID);
            removePlayersFromSearching(m.player1.id, msg.caller, m.matchID);
            playerStatus.put(msg.caller, _p_s);
            playerStatus.put(m.player1.id, _p_s);
            return (#Assigned, m.matchID, "Game found");
        };
    };
    switch (playerStatus.get(msg.caller)) {
        case (null) {};
        case (?_p) {
            switch (_p.status) {
                case (#Searching) {
                    let _active : Bool = activatePlayerSearching(msg.caller, _p.matchID);
                    if (_active == true) {
                        return (#Assigned, _p.matchID, "Searching for game");
                    };
                };
                case (#Reserved) {};
                case (#Accepting) {};
                case (#Accepted) {};
                case (#InGame) {};
                case (#Ended) {};
            };
        };
    };
    _matchID := _matchID + 1;
    let username = switch (await getUserDetails(msg.caller)) {
        case (null) { "" };
        case (?player) { player.username };
    };
    let _player : MMInfo = {
        id = msg.caller;
        elo = _pELO;
        matchAccepted = false;
        playerGameData = pgd;
        lastPlayerActive = Nat64.fromIntWrap(Time.now());
        username = username;
    };
    let _match : MatchData = {
        matchID = _matchID;
        player1 = _player;
        player2 = null;
        status = #Searching;
    };
    searching.put(_matchID, _match);
    let _ps : MMPlayerStatus = {
        status = #Searching;
        matchID = _matchID;
    };
    playerStatus.put(msg.caller, _ps);
    return (#Assigned, _matchID, "Lobby created");
};

func removePlayersFromSearching(p1 : Principal, p2 : Principal, matchID : Nat) {
    switch (playerStatus.get(p1)) {
        case (null) {};
        case (?_p1) {
            if (_p1.matchID != matchID) {
                searching.delete(_p1.matchID);
            };
        };
    };
    switch (playerStatus.get(p2)) {
        case (null) {};
        case (?_p2) {
            if (_p2.matchID != matchID) {
                searching.delete(_p2.matchID);
            };
        };
    };
};

  public shared (msg) func cancelMatchmaking() : async (Bool, Text) {
    assert (msg.caller != NULL_PRINCIPAL and msg.caller != ANON_PRINCIPAL);
    switch (playerStatus.get(msg.caller)) {
        case (null) {
            return (true, "Game not found for this player");
        };
        case (?_s) {
            if (_s.status == #Searching) {
                searching.delete(_s.matchID);
                playerStatus.delete(msg.caller);
                return (true, "Matchmaking canceled successfully");
            } else {
                return (false, "Match found, cannot cancel at this time");
            };
        };
    };
};

  func getOtherPlayer(_m : MatchData, caller : Principal) : ?Principal {
    switch (_m.player1.id == caller) {
      case (true) {
        switch (_m.player2) {
          case (null) {
            return (null);
          };
          case (?_p2) {
            return (?_p2.id);
          };
        };
      };
      case (false) {
        return (?_m.player1.id);
      };
    };
  };

  public shared query (msg) func isGameMatched() : async (Bool, Text) {
    switch (playerStatus.get(msg.caller)) {
      case (null) {
        return (false, "Game not found for this player");
      };
      case (?_s) {
        switch (searching.get(_s.matchID)) {
          case (null) {
            switch (inProgress.get(_s.matchID)) {
              case (null) {
                return (false, "Game not found for this player");
              };
              case (?_m) {
                return (true, "Game matched");
              };
            };
          };
          case (?_m) {
            switch (_m.player2) {
              case (null) {
                return (false, "Not matched yet");
              };
              case (?_p2) {
                return (true, "Game matched");
              };
            };
          };
        };
      };
    };
  };

  public query func getMatchData(matchID : Nat) : async ?MatchData {

    switch (searching.get(matchID)) {
      case (null) {
        switch (inProgress.get(matchID)) {
          case (null) {
            switch (finishedGames.get(matchID)) {
              case (null) {
                return (null);
              };
              case (?_m) {
                return (?_m);
              };
            };
          };
          case (?_m) {
            return (?_m);
          };
        };
      };
      case (?_m) {
        return (?_m);
      };
    };
  };

public shared composite query (msg) func getMyMatchData() : async (?FullMatchData, Nat) {
    assert (msg.caller != NULL_PRINCIPAL and msg.caller != ANON_PRINCIPAL);

    switch (playerStatus.get(msg.caller)) {
        case (null) return (null, 0);
        case (?_s) {
            let _m = switch (searching.get(_s.matchID)) {
                case (null) switch (inProgress.get(_s.matchID)) {
                    case (null) switch (finishedGames.get(_s.matchID)) {
                        case (null) return (null, 0);
                        case (?_m) _m;
                    };
                    case (?_m) _m;
                };
                case (?_m) _m;
            };

            let _p = if (_m.player1.id == msg.caller) 1 else switch (_m.player2) {
                case (null) return (null, 0);
                case (?_p2) 2;
            };

            let _p1Data = await getPlayerData(_m.player1.id);
            let _p1Name = switch (_p1Data) { case (null) ""; case (?p1) p1.username; };
            let _p1Avatar = switch (_p1Data) { case (null) 0; case (?p1) p1.avatar; };
            let _p1Level = switch (_p1Data) { case (null) 0; case (?p1) p1.level; };

            let _fullPlayer2 = switch (_m.player2) {
                case null null;
                case (?p2) {
                    let _p2D = await getPlayerData(p2.id);
                    ?{
                        id = p2.id;
                        username = switch (_p2D) { case (null) ""; case (?p) p.username; };
                        avatar = switch (_p2D) { case (null) 0; case (?p) p.avatar; };
                        level = switch (_p2D) { case (null) 0; case (?p) p.level; };
                        matchAccepted = p2.matchAccepted;
                        elo = p2.elo;
                        playerGameData = p2.playerGameData;
                    };
                };
            };

            let _fullPlayer1 = {
                id = _m.player1.id;
                username = _p1Name;
                avatar = _p1Avatar;
                level = _p1Level;
                matchAccepted = _m.player1.matchAccepted;
                elo = _m.player1.elo;
                playerGameData = _m.player1.playerGameData;
            };

            let fm : FullMatchData = {
                matchID = _m.matchID;
                player1 = _fullPlayer1;
                player2 = _fullPlayer2;
                status = _m.status;
            };

            return (?fm, _p);
        };
    };
};

public query func getAllSearching() : async [MatchData] {
    let _searchingList = Buffer.Buffer<MatchData>(searching.size());
    for (m in searching.vals()) {
        _searchingList.add(m);
    };
    return Buffer.toArray(_searchingList);
};

  //Rewards
  private stable var rewardID : Nat = 1;
  private var ONE_HOUR : Nat64 = 60 * 60 * 1_000_000_000; // 24 hours in nanoseconds
  private var NULL_PRINCIPAL : Principal = Principal.fromText("aaaaa-aa");
  private var ANON_PRINCIPAL : Principal = Principal.fromText("2vxsx-fae");
  private stable var _activeRewards : [(Nat, Reward)] = [];
  var activeRewards : HashMap.HashMap<Nat, Reward> = HashMap.fromIter(_activeRewards.vals(), 0, _natEqual, _natHash);
  private stable var _rewardsUsers : [(PlayerId, [RewardsUser])] = [];
  var rewardsUsers : HashMap.HashMap<PlayerId, [RewardsUser]> = HashMap.fromIter(_rewardsUsers.vals(), 0, Principal.equal, Principal.hash);
  private stable var _finishedRewardsUsers : [(PlayerId, [RewardsUser])] = [];
  var finishedRewardsUsers : HashMap.HashMap<PlayerId, [RewardsUser]> = HashMap.fromIter(_finishedRewardsUsers.vals(), 0, Principal.equal, Principal.hash);
  private stable var _expiredRewardsUsers : [(PlayerId, [RewardsUser])] = [];
  var expiredRewardsUsers : HashMap.HashMap<PlayerId, [RewardsUser]> = HashMap.fromIter(_expiredRewardsUsers.vals(), 0, Principal.equal, Principal.hash);
  private stable var _userLastReward : [(PlayerId, Nat)] = [];
  var userLastReward : HashMap.HashMap<PlayerId, Nat> = HashMap.fromIter(_userLastReward.vals(), 0, Principal.equal, Principal.hash);
  private stable var _expiredRewards : [(Nat, Reward)] = [];
  var expiredRewards : HashMap.HashMap<Nat, Reward> = HashMap.fromIter(_expiredRewards.vals(), 0, _natEqual, _natHash);

  public shared (msg) func addReward(reward : Reward) : async (Bool, Text, Nat) {
    if (Principal.notEqual(msg.caller, _cosmicraftsPrincipal)) {
      return (false, "Unauthorized", 0);
    };
    let _newID = rewardID;
    activeRewards.put(_newID, reward);
    rewardID := rewardID + 1;
    return (true, "Reward added successfully", _newID);
  };

  public query func getReward(rewardID : Nat) : async ?Reward {
    return (activeRewards.get(rewardID));
  };

  public shared query (msg) func getUserReward(_user : PlayerId, _idReward : Nat) : async ?RewardsUser {
    if (Principal.notEqual(msg.caller, _cosmicraftsPrincipal)) {
      return null;
    };
    switch (rewardsUsers.get(_user)) {
      case (null) {
        return null;
      };
      case (?rewardsu) {
        for (r in rewardsu.vals()) {
          if (r.id_reward == _idReward) {
            return ?r;
          };
        };
        return null;
      };
    };
  };

  public shared (msg) func claimedReward(_player: Principal, rewardID: Nat): async (Bool, Text) {
    if (Principal.notEqual(msg.caller, _cosmicraftsPrincipal)) {
        return (false, "Unauthorized");
    };
    switch (rewardsUsers.get(_player)) {
        case (null) {
            return (false, "User not found");
        };
        case (?rewardsu) {
            var _removed: Bool = false;
            var _message: Text = "Reward not found";
            let _userRewardsActive = Buffer.Buffer<RewardsUser>(rewardsu.size());
            for (r in rewardsu.vals()) {
                if (r.id_reward == rewardID) {
                    if (r.finished == true) {
                        let newUserRewardsFinished = Buffer.Buffer<RewardsUser>(
                            switch (finishedRewardsUsers.get(_player)) {
                                case (null) { 0 };
                                case (?rewardsf) { rewardsf.size() };
                            }
                        );
                        _removed := true;
                        _message := "Reward claimed successfully";
                        newUserRewardsFinished.add(r);
                        finishedRewardsUsers.put(_player, Buffer.toArray(newUserRewardsFinished));
                    } else {
                        _message := "Reward not finished yet";
                    };
                } else {
                    _userRewardsActive.add(r);
                };
            };
            rewardsUsers.put(_player, Buffer.toArray(_userRewardsActive));
            return (_removed, _message);
        };
    };
};

  public shared func addProgressToRewards(_player: Principal, rewardsProgress: [RewardProgress]): async (Bool, Text) {
    if (Principal.equal(_player, NULL_PRINCIPAL)) {
        return (false, "USER IS NULL. CANNOT ADD PROGRESS TO NULL USER");
    };
    if (Principal.equal(_player, ANON_PRINCIPAL)) {
        return (false, "USER IS ANONYMOUS. CANNOT ADD PROGRESS TO ANONYMOUS USER");
    };
    let _rewards_user: [RewardsUser] = switch (rewardsUsers.get(_player)) {
        case (null) {
            addNewRewardsToUser(_player);
        };
        case (?rewardsu) {
            rewardsu;
        };
    };
    if (_rewards_user.size() == 0) {
        return (false, "NO REWARDS FOUND FOR THIS USER");
    };
    if (rewardsProgress.size() == 0) {
        return (false, "NO PROGRESS FOUND FOR THIS USER");
    };
    let _newUserRewards = Buffer.Buffer<RewardsUser>(_rewards_user.size());
    let _now: Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    for (r in _rewards_user.vals()) {
        var _finished = r.finished;
        if (_finished == false and r.start_date <= _now) {
            if (r.expiration < _now) {
                let newUserRewardsExpired = Buffer.Buffer<RewardsUser>(
                    switch (expiredRewardsUsers.get(_player)) {
                        case (null) { 0 };
                        case (?rewardse) { rewardse.size() };
                    }
                );
                newUserRewardsExpired.add(r);
                expiredRewardsUsers.put(_player, Buffer.toArray(newUserRewardsExpired));
            } else {
                for (rp in rewardsProgress.vals()) {
                    if (r.rewardType == rp.rewardType) {
                        let _progress = r.progress + rp.progress;
                        var _finishedDate = r.finish_date;
                        if (_progress >= r.total) {
                            _finished := true;
                            _finishedDate := _now;
                        };
                        let _r_u: RewardsUser = {
                            expiration = r.expiration;
                            start_date = r.start_date;
                            finish_date = _finishedDate;
                            finished = _finished;
                            id_reward = r.id_reward;
                            prize_amount = r.prize_amount;
                            prize_type = r.prize_type;
                            progress = _progress;
                            rewardType = r.rewardType;
                            total = r.total;
                        };
                        _newUserRewards.add(_r_u);
                    };
                };
            };
        } else {
            _newUserRewards.add(r);
        };
    };
    rewardsUsers.put(_player, Buffer.toArray(_newUserRewards));
    return (true, "Progress added successfully for " # Nat.toText(_newUserRewards.size()) # " rewards");
};


  func getAllUnexpiredActiveRewards(_from: ?Nat): [Reward] {
    let _now: Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    let _activeRewards = Buffer.Buffer<Reward>(activeRewards.size());
    let _fromNat: Nat = switch (_from) {
        case (null) { 0 };
        case (?f) { f };
    };
    for (r in activeRewards.vals()) {
        if (r.id > _fromNat) {
            if (r.start_date <= _now) {
                if (r.end_date < _now) {
                    let _expR = activeRewards.remove(r.id);
                    switch (_expR) {
                        case (null) {
                        };
                        case (?er) {
                            expiredRewards.put(er.id, er);
                        };
                    };
                } else {
                    _activeRewards.add(r);
                };
            };
        };
    };
    return Buffer.toArray(_activeRewards);
};

  public query func getAllUsersRewards() : async ([(Principal, [RewardsUser])]) {
    return Iter.toArray(rewardsUsers.entries());
  };

public query func getAllActiveRewards(): async (Nat, [(Reward)]) {
    let _activeRewards = Buffer.Buffer<Reward>(activeRewards.size());
    var _expired: Nat = 0;
    let _now: Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    for (r in activeRewards.vals()) {
        if (r.start_date <= _now) {
            if (r.end_date < _now) {
                _expired := _expired + 1;
            } else {
                _activeRewards.add(r);
            };
        };
    };
    return (_expired, Buffer.toArray(_activeRewards));
};

  func addNewRewardsToUser(_player: Principal): [RewardsUser] {
    let _newUserRewards = Buffer.Buffer<RewardsUser>(0);
    switch (userLastReward.get(_player)) {
        case (null) {
            let _unexpiredRewards = getAllUnexpiredActiveRewards(null);
            for (r in _unexpiredRewards.vals()) {
                let _r_u: RewardsUser = {
                    expiration = r.end_date;
                    start_date = r.start_date;
                    finish_date = r.end_date;
                    finished = false;
                    id_reward = r.id;
                    prize_amount = r.prize_amount;
                    prize_type = r.prize_type;
                    progress = 0;
                    rewardType = r.rewardType;
                    total = r.total;
                };
                _newUserRewards.add(_r_u);
            };
        };
        case (lastReward) {
            let _unexpiredRewards = getAllUnexpiredActiveRewards(lastReward);
            for (r in _unexpiredRewards.vals()) {
                let _r_u: RewardsUser = {
                    expiration = r.end_date;
                    start_date = r.start_date;
                    finish_date = r.end_date;
                    finished = false;
                    id_reward = r.id;
                    prize_amount = r.prize_amount;
                    prize_type = r.prize_type;
                    progress = 0;
                    rewardType = r.rewardType;
                    total = r.total;
                };
                _newUserRewards.add(_r_u);
            };
        };
    };
    switch (rewardsUsers.get(_player)) {
        case (null) {
            userLastReward.put(_player, rewardID);
            rewardsUsers.put(_player, Buffer.toArray(_newUserRewards));
            return Buffer.toArray(_newUserRewards);
        };
        case (?rewardsu) {
            let _newRewards = Buffer.Buffer<RewardsUser>(rewardsu.size() + _newUserRewards.size());
            for (r in rewardsu.vals()) {
                _newRewards.add(r);
            };
            for (r in _newUserRewards.vals()) {
                _newRewards.add(r);
            };
            userLastReward.put(_player, rewardID);
            rewardsUsers.put(_player, Buffer.toArray(_newRewards));
            return Buffer.toArray(_newRewards);
        };
    };
};

  public shared func createReward(name : Text, rewardType : RewardType, prizeType : PrizeType, prizeAmount : Nat, total : Float, hours_active : Nat64) : async (Bool, Text) {
    let _now : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    let _hoursActive = ONE_HOUR * hours_active;
    let endDate = _now + _hoursActive;
    // if(Principal.notEqual(msg.caller, _cosmicraftsPrincipal)){
    //     return (false, "Unauthorized");
    // };
    let _newReward : Reward = {
      end_date = endDate;
      id = rewardID;
      name = name;
      prize_amount = prizeAmount;
      prize_type = prizeType;
      rewardType = rewardType;
      start_date = _now;
      total = total;
    };
    activeRewards.put(rewardID, _newReward);
    rewardID := rewardID + 1;
    return (true, "Reward created successfully");
  };
};
