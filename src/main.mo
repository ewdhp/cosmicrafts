// main.mo
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
import Types "Types";
import Utils "Utils";

shared actor class Cosmicrafts() {

  //Types.mo
  public type PlayerId = Types.PlayerId;
  public type UserID = Types.UserID;
  public type Username = Types.Username;
  public type AvatarID = Types.AvatarID;
  public type Description = Types.Description;
  public type RegistrationDate = Types.RegistrationDate;

  public type PlayerName = Types.PlayerName;
  public type Level = Types.Level;
  public type GameID = Types.GameID;
  public type Players = Types.Players;
  public type UserRecord = Types.UserRecord;
  public type FriendDetails = Types.FriendDetails;
  public type Player = Types.Player;
  public type PlayerPreferences = Types.PlayerPreferences;
  public type UserDetails = Types.UserDetails;

  public type StastisticsGameID = Types.StastisticsGameID;
  public type PlayerID = Types.PlayerID;
  public type GamesWithFaction = Types.GamesWithFaction;
  public type GamesWithGameMode = Types.GamesWithGameMode;
  public type GamesWithCharacter = Types.GamesWithCharacter;
  public type BasicStats = Types.BasicStats;
  public type PlayerGamesStats = Types.PlayerGamesStats;
  public type OverallStats = Types.OverallStats;
  public type AverageStats = Types.AverageStats;

  public type RewardType = Types.RewardType;
  public type PrizeType = Types.PrizeType;
  public type Reward = Types.Reward;
  public type RewardsUser = Types.RewardsUser;
  public type RewardProgress = Types.RewardProgress;

  public type UserId = Types.UserId;
  public type PlayerInfo = Types.PlayerInfo;
  public type FullPlayerInfo = Types.FullPlayerInfo;
  public type MatchmakingStatus = Types.MatchmakingStatus;
  public type PlayerStatus = Types.PlayerStatus;
  public type MatchData = Types.MatchData;
  public type FullMatchData = Types.FullMatchData;
  public type SearchStatus = Types.SearchStatus;

  //Players
  private stable var _userRecords : [(UserID, UserRecord)] = [];
  var userRecords : HashMap.HashMap<UserID, UserRecord> = HashMap.fromIter(_userRecords.vals(), 0, Principal.equal, Principal.hash);

  //Migrated Players must decide wich register function use oldor new...

  //type Username = PlayerTypes.Username;

  private stable var _players : [(PlayerId, Player)] = [];
  var players : HashMap.HashMap<PlayerId, Player> = HashMap.fromIter(_players.vals(), 0, Principal.equal, Principal.hash);
  private stable var _playerPreferences : [(PlayerId, PlayerPreferences)] = [];
  var playerPreferences : HashMap.HashMap<PlayerId, PlayerPreferences> = HashMap.fromIter(_playerPreferences.vals(), 0, Principal.equal, Principal.hash);

  private stable var overallStats : OverallStats = {
    totalGamesPlayed : Nat = 0;
    totalGamesSP : Nat = 0;
    totalGamesMP : Nat = 0;
    totalDamageDealt : Float = 0;
    totalTimePlayed : Float = 0;
    totalKills : Float = 0;
    totalEnergyGenerated : Float = 0;
    totalEnergyUsed : Float = 0;
    totalEnergyWasted : Float = 0;
    totalXpEarned : Float = 0;
    totalGamesWithFaction : [GamesWithFaction] = [];
    totalGamesGameMode : [GamesWithGameMode] = [];
    totalGamesWithCharacter : [GamesWithCharacter] = [];
  };

  public shared ({ caller : UserID }) func registerUser(username : Username, avatar : AvatarID) : async (Bool, UserID) {
    let userId = caller;
    switch (userRecords.get(userId)) {
      case (null) {
        let registrationDate = Time.now();
        let newUserRecord : UserRecord = {
          userId = userId;
          username = username;
          avatar = avatar;
          friends = [];
          description = "";
          registrationDate = registrationDate;
        };
        userRecords.put(userId, newUserRecord);
        return (true, userId);
      };
      case (?_) {
        return (false, userId); // User already exists
      };
    };
  };

  public shared ({ caller : UserID }) func updateUsername(username : Username) : async (Bool, UserID) {
    let userId = caller;
    switch (userRecords.get(userId)) {
      case (null) {
        return (false, userId); // User record does not exist
      };
      case (?userRecord) {
        let updatedRecord : UserRecord = {
          userId = userRecord.userId;
          username = username;
          avatar = userRecord.avatar;
          friends = userRecord.friends;
          description = userRecord.description;
          registrationDate = userRecord.registrationDate;
        };
        userRecords.put(userId, updatedRecord);
        return (true, userId);
      };
    };
  };

  public shared ({ caller : UserID }) func updateAvatar(avatar : AvatarID) : async (Bool, UserID) {
    let userId = caller;
    switch (userRecords.get(userId)) {
      case (null) {
        return (false, userId); // User record does not exist
      };
      case (?userRecord) {
        let updatedRecord : UserRecord = {
          userId = userRecord.userId;
          username = userRecord.username;
          avatar = avatar;
          friends = userRecord.friends;
          description = userRecord.description;
          registrationDate = userRecord.registrationDate;
        };
        userRecords.put(userId, updatedRecord);
        return (true, userId);
      };
    };
  };

  public shared ({ caller : UserID }) func updateDescription(description : Description) : async (Bool, UserID) {
    let userId = caller;
    switch (userRecords.get(userId)) {
      case (null) {
        return (false, userId); // User record does not exist
      };
      case (?userRecord) {
        let updatedRecord : UserRecord = {
          userId = userRecord.userId;
          username = userRecord.username;
          avatar = userRecord.avatar;
          friends = userRecord.friends;
          description = description;
          registrationDate = userRecord.registrationDate;
        };
        userRecords.put(userId, updatedRecord);
        return (true, userId);
      };
    };
  };

  public query func getUserDetails(user : UserID) : async ?UserDetails {
    switch (userRecords.get(user)) {
      case (?userRecord) {
        let friendsBuffer = Buffer.Buffer<FriendDetails>(userRecord.friends.size());
        for (friendId in userRecord.friends.vals()) {
          switch (userRecords.get(friendId)) {
            case (?friendRecord) {
              let friendDetails : FriendDetails = {
                userId = friendRecord.userId;
                username = friendRecord.username;
                avatar = friendRecord.avatar;
              };
              friendsBuffer.add(friendDetails);
            };
            case null {};
          };
        };
        let friendsList = Buffer.toArray(friendsBuffer);
        return ?{ user = userRecord; friends = friendsList };
      };
      case null {
        return null;
      };
    };
  };

  public query func searchUserByUsername(username : Username) : async [UserRecord] {
    let result : Buffer.Buffer<UserRecord> = Buffer.Buffer<UserRecord>(0);
    for ((_, userRecord) in userRecords.entries()) {
      if (userRecord.username == username) {
        result.add(userRecord);
      };
    };
    return Buffer.toArray(result);
  };

  public query func searchUserByPrincipal(userId : UserID) : async ?UserRecord {
    return userRecords.get(userId);
  };

  public shared ({ caller : UserID }) func addFriend(friendId : UserID) : async (Bool, Text) {
    let userId = caller;
    switch (userRecords.get(userId)) {
      case (null) {
        return (false, "User record does not exist"); // User record does not exist
      };
      case (?userRecord) {
        switch (userRecords.get(friendId)) {
          case (null) {
            return (false, "Friend principal not registered"); // Friend principal not registered
          };
          case (?_) {
            let updatedFriends = Buffer.Buffer<UserID>(userRecord.friends.size() + 1);
            for (friend in userRecord.friends.vals()) {
              updatedFriends.add(friend);
            };
            updatedFriends.add(friendId);
            let updatedRecord : UserRecord = {
              userId = userRecord.userId;
              username = userRecord.username;
              avatar = userRecord.avatar;
              friends = Buffer.toArray(updatedFriends);
              description = userRecord.description;
              registrationDate = userRecord.registrationDate;
            };
            userRecords.put(userId, updatedRecord);
            return (true, "Friend added successfully");
          };
        };
      };
    };
  };

  public query ({ caller : UserID }) func getFriendsList() : async ?[UserID] {
    let userId = caller;
    switch (userRecords.get(userId)) {
      case (null) {
        return null; // User record does not exist
      };
      case (?userRecord) {
        return ?userRecord.friends;
      };
    };
  };

  //////////////////////////////////
  //analize if its necesary all these three functions...
  /// PLAYERS LOGIC
  public shared (msg) func getPlayer() : async ?Player {
    return players.get(msg.caller);
  };

  public composite query func getPlayerData(player : Principal) : async ?Player {
    return players.get(player);
  };

  public shared query (msg) func getMyPlayerData() : async ?Player {
    return players.get(msg.caller);
  };
  //////////////////////////////////
  public shared (msg) func createPlayer(name : Text) : async (Bool, Text) {
    switch (players.get(msg.caller)) {
      case (null) {
        let _level = 0;
        let player : Player = {
          id = msg.caller;
          name = name;
          level = _level;
          elo = 1200;
        };
        players.put(msg.caller, player);
        let preferences : PlayerPreferences = {
          language = 0;
          playerChar = "";
        };
        playerPreferences.put(msg.caller, preferences);
        return (true, "Player created");
      };
      case (?_) {
        return (false, "Player already exists");
      };
    };
  };

  public shared (msg) func savePlayerName(name : Text) : async Bool {
    switch (players.get(msg.caller)) {
      case (null) {
        return false;
      };
      case (?player) {
        let _playerNew : Player = {
          id = player.id;
          name = name;
          level = player.level;
          elo = player.elo;
        };
        players.put(msg.caller, _playerNew);
        return true;
      };
    };
  };

  public shared (msg) func getPlayerPreferences() : async ?PlayerPreferences {
    return playerPreferences.get(msg.caller);
  };

  public shared (msg) func savePlayerChar(_char : Text) : async (Bool, Text) {
    switch (playerPreferences.get(msg.caller)) {
      case (null) {
        return (false, "Player not found");
      };
      case (?_p) {
        let _playerNew : PlayerPreferences = {
          language = _p.language;
          playerChar = _char;
        };
        playerPreferences.put(msg.caller, _playerNew);
        return (true, "Player's character saved");
      };
    };
  };

  public shared (msg) func savePlayerLanguage(_lang : Nat) : async (Bool, Text) {
    switch (playerPreferences.get(msg.caller)) {
      case (null) {
        return (false, "Player not found");
      };
      case (?_p) {
        let _playerNew : PlayerPreferences = {
          language = _lang;
          playerChar = _p.playerChar;
        };
        playerPreferences.put(msg.caller, _playerNew);
        return (true, "Player's language saved");
      };
    };
  };

  public query func getAllPlayers() : async [Player] {
    return Iter.toArray(players.vals());
  };

  public query func getPlayerElo(player : Principal) : async Float {
    return switch (players.get(player)) {
      case (null) {
        1200;
      };
      case (?_p) {
        _p.elo;
      };
    };
  };

  public shared func updatePlayerElo(player : Principal, newELO : Float) : async Bool {
    // assert (msg.caller == _statisticPrincipal); /// Only Statistics Canister can update ELO, change for statistics principal later
    let _player : Player = switch (players.get(player)) {
      case (null) {
        return false;
      };
      case (?_p) {
        _p;
      };
    };
    /// Update ELO on player's data
    let _playerNew : Player = {
      id = _player.id;
      name = _player.name;
      level = _player.level;
      elo = newELO;
    };
    players.put(player, _playerNew);
    return true;
  };

  //Statistics
  private stable var _cosmicraftsPrincipal : Principal = Principal.fromText("woimf-oyaaa-aaaan-qegia-cai");
  private stable var k : Int = 30;

  func _natEqual(a : Nat, b : Nat) : Bool {
    return a == b;
  };

  
// Convert Nat to a sequence of Nat8 bytes
  func _natHash(a: Nat): Hash.Hash {
    return Utils._natHash(a);
  };

  private stable var _basicStats : [(StastisticsGameID, BasicStats)] = [];
  var basicStats : HashMap.HashMap<StastisticsGameID, BasicStats> = HashMap.fromIter(_basicStats.vals(), 0, _natEqual, _natHash);
  private stable var _playerGamesStats : [(PlayerID, PlayerGamesStats)] = [];
  var playerGamesStats : HashMap.HashMap<PlayerID, PlayerGamesStats> = HashMap.fromIter(_playerGamesStats.vals(), 0, Principal.equal, Principal.hash);
  private stable var _onValidation : [(StastisticsGameID, BasicStats)] = [];
  var onValidation : HashMap.HashMap<StastisticsGameID, BasicStats> = HashMap.fromIter(_onValidation.vals(), 0, _natEqual, _natHash);

  private func _initializeNewPlayerStats(_player : Principal) : async (Bool, Text) {
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
    playerGamesStats.put(_player, _playerStats);
    return (true, "Player stats initialized");
  };

  private func updatePlayerELO(playerID : PlayerID, won : Nat, otherPlayerID : ?PlayerID) : async Bool {
    switch (otherPlayerID) {
      case (null) {
        return false;
      };
      case (?_p) {
        /// Get both player's ELO
        var _p1Elo : Float = await getPlayerElo(playerID);
        let _p2Elo : Float = await getPlayerElo(_p);
        /// Calculate expected results
        let _p1Expected : Float = 1 / (1 + Float.pow(10, (_p2Elo - _p1Elo) / 400));
        let _p2Expected : Float = 1 / (1 + Float.pow(10, (_p1Elo - _p2Elo) / 400));
        /// Update ELO
        let _elo : Float = _p1Elo + Float.fromInt(k) * (Float.fromInt64(Int64.fromInt(won)) - _p1Expected);
        let _updated = await updatePlayerElo(playerID, _elo);
        return true;
      };
    };
  };

  public shared (msg) func setGameOver(caller : Principal) : async (Bool, Bool, ?Principal) {
    assert (msg.caller == Principal.fromText("ajuq4-ruaaa-aaaaa-qaaga-cai")); //main canisterID
    switch (playerStatus.get(caller)) {
      case (null) {
        return (false, false, null);
      };
      case (?_s) {
        switch (inProgress.get(_s.matchID)) {
          case (null) {
            switch (searching.get(_s.matchID)) {
              case (null) {
                switch (finishedGames.get(_s.matchID)) {
                  case (null) {
                    return (false, false, null);
                  };
                  case (?_m) {
                    /// Game is not on the searching on inProgress, so we just remove the status from the player
                    playerStatus.delete(caller);
                    return (true, caller == _m.player1.id, getOtherPlayer(_m, caller));
                  };
                };
              };
              case (?_m) {
                /// Game is on Searching list, so we remove it, add it to the finished list and remove the status from the player
                finishedGames.put(_s.matchID, _m);
                searching.delete(_s.matchID);
                playerStatus.delete(caller);
                return (true, caller == _m.player1.id, getOtherPlayer(_m, caller));
              };
            };
          };
          case (?_m) {
            /// Game is on inProgress list, so we remove it, add it to the finished list and remove the status from the player
            finishedGames.put(_s.matchID, _m);
            inProgress.delete(_s.matchID);
            playerStatus.delete(caller);
            return (true, caller == _m.player1.id, getOtherPlayer(_m, caller));
          };
        };
      };
    };
  };

  public shared (msg) func saveFinishedGame(StastisticsGameID : StastisticsGameID, _basicStats : BasicStats) : async (Bool, Text) {
    /// End game on the matchmaking canister
    var _txt : Text = "";
    switch (basicStats.get(StastisticsGameID)) {
      case (null) {
        let endingGame : (Bool, Bool, ?Principal) = await setGameOver(msg.caller);
        basicStats.put(StastisticsGameID, _basicStats);
        let _gameValid : (Bool, Text) = await validateGame(300 - _basicStats.secRemaining, _basicStats.energyUsed, _basicStats.xpEarned, 0.5);
        if (_gameValid.0 == false) {
          onValidation.put(StastisticsGameID, _basicStats);
          return (false, _gameValid.1);
        };
        /// Player stats
        let _winner = if (_basicStats.wonGame == true) 1 else 0;
        let _looser = if (_basicStats.wonGame == false) 1 else 0;
        let _elo : Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);
        var _progressRewards : Buffer.Buffer<RewardProgress> = Buffer.Buffer<RewardProgress>(1);
        _progressRewards.add({
          rewardType = #GamesCompleted;
          progress = 1;
        });
        if (_basicStats.wonGame == true) {
          _progressRewards.add({
            rewardType = #GamesWon;
            progress = 1;
          });
        };
        let _progressAdded = await addProgressToRewards(msg.caller, Buffer.toArray(_progressRewards));
        _txt := _progressAdded.1;
        switch (playerGamesStats.get(msg.caller)) {
          case (null) {
            let _gs : PlayerGamesStats = {
              gamesPlayed = 1;
              gamesWon = _winner;
              gamesLost = _looser;
              energyGenerated = _basicStats.energyGenerated;
              energyUsed = _basicStats.energyUsed;
              energyWasted = _basicStats.energyWasted;
              totalDamageDealt = _basicStats.damageDealt;
              totalDamageTaken = _basicStats.damageTaken;
              totalDamageCrit = _basicStats.damageCritic;
              totalDamageEvaded = _basicStats.damageEvaded;
              totalXpEarned = _basicStats.xpEarned;
              totalGamesWithFaction = [{
                factionID = _basicStats.faction;
                gamesPlayed = 1;
                gamesWon = _winner;
              }];
              totalGamesGameMode = [{
                gameModeID = _basicStats.gameMode;
                gamesPlayed = 1;
                gamesWon = _winner;
              }];
              totalGamesWithCharacter = [{
                characterID = _basicStats.characterID;
                gamesPlayed = 1;
                gamesWon = _winner;
              }];
            };
            playerGamesStats.put(msg.caller, _gs);
          };
          case (?_bs) {
            var _gamesWithFaction = Buffer.Buffer<GamesWithFaction>(_bs.totalGamesWithFaction.size() + 1);
            var _gamesWithGameMode = Buffer.Buffer<GamesWithGameMode>(_bs.totalGamesGameMode.size() + 1);
            var _totalGamesWithCharacter = Buffer.Buffer<GamesWithCharacter>(_bs.totalGamesWithCharacter.size() + 1);
            for (gf in _bs.totalGamesWithFaction.vals()) {
              if (gf.factionID == _basicStats.faction) {
                _gamesWithFaction.add({ gamesPlayed = gf.gamesPlayed + 1; factionID = gf.factionID; gamesWon = gf.gamesWon + _winner });
              } else {
                _gamesWithFaction.add(gf);
              };
            };
            for (gm in _bs.totalGamesGameMode.vals()) {
              if (gm.gameModeID == _basicStats.gameMode) {
                _gamesWithGameMode.add({ gamesPlayed = gm.gamesPlayed + 1; gameModeID = gm.gameModeID; gamesWon = gm.gamesWon + _winner });
              } else {
                _gamesWithGameMode.add(gm);
              };
            };
            for (gc in _bs.totalGamesWithCharacter.vals()) {
              if (gc.characterID == _basicStats.characterID) {
                _totalGamesWithCharacter.add({ gamesPlayed = gc.gamesPlayed + 1; characterID = gc.characterID; gamesWon = gc.gamesWon + _winner });
              } else {
                _totalGamesWithCharacter.add(gc);
              };
            };
            var _thisGameXP = _basicStats.xpEarned;
            if (_basicStats.wonGame == true) {
              _thisGameXP := _thisGameXP * 2;
            } else {
              _thisGameXP := _thisGameXP * 0.5;
            };
            if (_basicStats.gameMode == 1) {
              _thisGameXP := _thisGameXP * 2;
            } else {
              _thisGameXP := _thisGameXP * 0.25;
            };
            let _gs : PlayerGamesStats = {
              gamesPlayed = _bs.gamesPlayed + 1;
              gamesWon = _bs.gamesWon + _winner;
              gamesLost = _bs.gamesLost + _looser;
              energyGenerated = _bs.energyGenerated + _basicStats.energyGenerated;
              energyUsed = _bs.energyUsed + _basicStats.energyUsed;
              energyWasted = _bs.energyWasted + _basicStats.energyWasted;
              totalDamageDealt = _bs.totalDamageDealt + _basicStats.damageDealt;
              totalDamageTaken = _bs.totalDamageTaken + _basicStats.damageTaken;
              totalDamageCrit = _bs.totalDamageCrit + _basicStats.damageCritic;
              totalDamageEvaded = _bs.totalDamageEvaded + _basicStats.damageEvaded;
              totalXpEarned = _bs.totalXpEarned + _thisGameXP;
              totalGamesWithFaction = Buffer.toArray(_gamesWithFaction);
              totalGamesGameMode = Buffer.toArray(_gamesWithGameMode);
              totalGamesWithCharacter = Buffer.toArray(_totalGamesWithCharacter);
            };
            playerGamesStats.put(msg.caller, _gs);
          };
        };
        /// Overall stats
        var _totalGamesWithFaction = Buffer.Buffer<GamesWithFaction>(overallStats.totalGamesWithFaction.size() + 1);
        var _totalGamesWithGameMode = Buffer.Buffer<GamesWithGameMode>(overallStats.totalGamesGameMode.size() + 1);
        var _totalGamesWithCharacter = Buffer.Buffer<GamesWithCharacter>(overallStats.totalGamesWithCharacter.size() + 1);
        for (gf in overallStats.totalGamesWithFaction.vals()) {
          if (gf.factionID == _basicStats.faction) {
            _totalGamesWithFaction.add({ gamesPlayed = gf.gamesPlayed + 1; factionID = gf.factionID; gamesWon = gf.gamesWon + _winner });
          } else {
            _totalGamesWithFaction.add(gf);
          };
        };
        for (gm in overallStats.totalGamesGameMode.vals()) {
          if (gm.gameModeID == _basicStats.gameMode) {
            _totalGamesWithGameMode.add({ gamesPlayed = gm.gamesPlayed + 1; gameModeID = gm.gameModeID; gamesWon = gm.gamesWon + _winner });
          } else {
            _totalGamesWithGameMode.add(gm);
          };
        };
        for (gc in overallStats.totalGamesWithCharacter.vals()) {
          if (gc.characterID == _basicStats.characterID) {
            _totalGamesWithCharacter.add({ gamesPlayed = gc.gamesPlayed + 1; characterID = gc.characterID; gamesWon = gc.gamesWon + _winner });
          } else {
            _totalGamesWithCharacter.add(gc);
          };
        };
        let _os : OverallStats = {
          totalGamesPlayed = overallStats.totalGamesPlayed + 1;
          totalGamesSP = if (_basicStats.gameMode == 2) overallStats.totalGamesSP + 1 else overallStats.totalGamesSP;
          totalGamesMP = if (_basicStats.gameMode == 1) overallStats.totalGamesMP + 1 else overallStats.totalGamesMP;
          totalDamageDealt = overallStats.totalDamageDealt + _basicStats.damageDealt;
          totalTimePlayed = overallStats.totalTimePlayed;
          totalKills = overallStats.totalKills + _basicStats.kills;
          totalEnergyUsed = overallStats.totalEnergyUsed + _basicStats.energyUsed;
          totalEnergyGenerated = overallStats.totalEnergyGenerated + _basicStats.energyGenerated;
          totalEnergyWasted = overallStats.totalEnergyWasted + _basicStats.energyWasted;
          totalGamesWithFaction = Buffer.toArray(_totalGamesWithFaction);
          totalGamesGameMode = Buffer.toArray(_totalGamesWithGameMode);
          totalGamesWithCharacter = Buffer.toArray(_totalGamesWithCharacter);
          totalXpEarned = overallStats.totalXpEarned + _basicStats.xpEarned;
        };
        overallStats := _os;
        return (true, "Game saved");
      };
      case (?_bs) {
        /// Was saved before, only save the respective variables
        /// Also validate info vs other save
        let endingGame = await setGameOver(msg.caller);
        let _winner = if (_basicStats.wonGame == true) 1 else 0;
        let _looser = if (_basicStats.wonGame == false) 1 else 0;
        let _elo : Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);
        var _progressRewards : Buffer.Buffer<RewardProgress> = Buffer.Buffer<RewardProgress>(1);
        _progressRewards.add({
          rewardType = #GamesCompleted;
          progress = 1;
        });
        if (_basicStats.wonGame == true) {
          _progressRewards.add({
            rewardType = #GamesWon;
            progress = 1;
          });
        };
        let _progressAdded = await addProgressToRewards(msg.caller, Buffer.toArray(_progressRewards));
        _txt := _progressAdded.1;
        switch (playerGamesStats.get(msg.caller)) {
          case (null) {
            let _gs : PlayerGamesStats = {
              gamesPlayed = 1;
              gamesWon = _winner;
              gamesLost = _looser;
              energyGenerated = _basicStats.energyGenerated;
              energyUsed = _basicStats.energyUsed;
              energyWasted = _basicStats.energyWasted;
              totalDamageDealt = _basicStats.damageDealt;
              totalDamageTaken = _basicStats.damageTaken;
              totalDamageCrit = _basicStats.damageCritic;
              totalDamageEvaded = _basicStats.damageEvaded;
              totalXpEarned = _basicStats.xpEarned;
              totalGamesWithFaction = [{
                factionID = _basicStats.faction;
                gamesPlayed = 1;
                gamesWon = _winner;
              }];
              totalGamesGameMode = [{
                gameModeID = _basicStats.gameMode;
                gamesPlayed = 1;
                gamesWon = _winner;
              }];
              totalGamesWithCharacter = [{
                characterID = _basicStats.characterID;
                gamesPlayed = 1;
                gamesWon = _winner;
              }];
            };
            playerGamesStats.put(msg.caller, _gs);
          };
          case (?_bs) {
            var _gamesWithFaction = Buffer.Buffer<GamesWithFaction>(_bs.totalGamesWithFaction.size() + 1);
            var _gamesWithGameMode = Buffer.Buffer<GamesWithGameMode>(_bs.totalGamesGameMode.size() + 1);
            var _totalGamesWithCharacter = Buffer.Buffer<GamesWithCharacter>(_bs.totalGamesWithCharacter.size() + 1);
            for (gf in _bs.totalGamesWithFaction.vals()) {
              if (gf.factionID == _basicStats.faction) {
                _gamesWithFaction.add({ gamesPlayed = gf.gamesPlayed + 1; factionID = gf.factionID; gamesWon = gf.gamesWon + _winner });
              } else {
                _gamesWithFaction.add(gf);
              };
            };
            for (gm in _bs.totalGamesGameMode.vals()) {
              if (gm.gameModeID == _basicStats.gameMode) {
                _gamesWithGameMode.add({ gamesPlayed = gm.gamesPlayed + 1; gameModeID = gm.gameModeID; gamesWon = gm.gamesWon + _winner });
              } else {
                _gamesWithGameMode.add(gm);
              };
            };
            for (gc in _bs.totalGamesWithCharacter.vals()) {
              if (gc.characterID == _basicStats.characterID) {
                _totalGamesWithCharacter.add({ gamesPlayed = gc.gamesPlayed + 1; characterID = gc.characterID; gamesWon = gc.gamesWon + _winner });
              } else {
                _totalGamesWithCharacter.add(gc);
              };
            };
            var _thisGameXP = _basicStats.xpEarned;
            if (_basicStats.wonGame == true) {
              _thisGameXP := _thisGameXP * 2;
            } else {
              _thisGameXP := _thisGameXP * 0.5;
            };
            if (_basicStats.gameMode == 1) {
              _thisGameXP := _thisGameXP * 2;
            } else {
              _thisGameXP := _thisGameXP * 0.25;
            };
            let _gs : PlayerGamesStats = {
              gamesPlayed = _bs.gamesPlayed + 1;
              gamesWon = _bs.gamesWon + _winner;
              gamesLost = _bs.gamesLost + _looser;
              energyGenerated = _bs.energyGenerated + _basicStats.energyGenerated;
              energyUsed = _bs.energyUsed + _basicStats.energyUsed;
              energyWasted = _bs.energyWasted + _basicStats.energyWasted;
              totalDamageDealt = _bs.totalDamageDealt + _basicStats.damageDealt;
              totalDamageTaken = _bs.totalDamageTaken + _basicStats.damageTaken;
              totalDamageCrit = _bs.totalDamageCrit + _basicStats.damageCritic;
              totalDamageEvaded = _bs.totalDamageEvaded + _basicStats.damageEvaded;
              totalXpEarned = _bs.totalXpEarned + _thisGameXP;
              totalGamesWithFaction = Buffer.toArray(_gamesWithFaction);
              totalGamesGameMode = Buffer.toArray(_gamesWithGameMode);
              totalGamesWithCharacter = Buffer.toArray(_totalGamesWithCharacter);
            };
            playerGamesStats.put(msg.caller, _gs);
          };
        };
        /// Overall stats
        var _totalGamesWithFaction = Buffer.Buffer<GamesWithFaction>(overallStats.totalGamesWithFaction.size() + 1);
        var _totalGamesWithCharacter = Buffer.Buffer<GamesWithCharacter>(overallStats.totalGamesWithCharacter.size() + 1);
        for (gf in overallStats.totalGamesWithFaction.vals()) {
          if (gf.factionID == _basicStats.faction) {
            _totalGamesWithFaction.add({ gamesPlayed = gf.gamesPlayed + 1; factionID = gf.factionID; gamesWon = gf.gamesWon + _winner });
          } else {
            _totalGamesWithFaction.add(gf);
          };
        };
        for (gc in overallStats.totalGamesWithCharacter.vals()) {
          if (gc.characterID == _basicStats.characterID) {
            _totalGamesWithCharacter.add({ gamesPlayed = gc.gamesPlayed + 1; characterID = gc.characterID; gamesWon = gc.gamesWon + _winner });
          } else {
            _totalGamesWithCharacter.add(gc);
          };
        };
        let _os : OverallStats = {
          totalGamesPlayed = overallStats.totalGamesPlayed + 1;
          totalGamesSP = if (_basicStats.gameMode == 2) overallStats.totalGamesSP + 1 else overallStats.totalGamesSP;
          totalGamesMP = if (_basicStats.gameMode == 1) overallStats.totalGamesMP + 1 else overallStats.totalGamesMP;
          totalDamageDealt = overallStats.totalDamageDealt + _basicStats.damageDealt;
          totalTimePlayed = overallStats.totalTimePlayed;
          totalKills = overallStats.totalKills + _basicStats.kills;
          totalEnergyUsed = overallStats.totalEnergyUsed + _basicStats.energyUsed;
          totalEnergyGenerated = overallStats.totalEnergyGenerated + _basicStats.energyGenerated;
          totalEnergyWasted = overallStats.totalEnergyWasted + _basicStats.energyWasted;
          totalGamesWithFaction = Buffer.toArray(_totalGamesWithFaction);
          totalGamesGameMode = overallStats.totalGamesGameMode;
          totalGamesWithCharacter = Buffer.toArray(_totalGamesWithCharacter);
          totalXpEarned = overallStats.totalXpEarned + _basicStats.xpEarned;
        };
        overallStats := _os;
        return (true, _txt # " - Game saved");
      };
    };
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

  public shared query func getBasicStats(StastisticsGameID : StastisticsGameID) : async ?BasicStats {
    return basicStats.get(StastisticsGameID);
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

  public query func getAllOnValidation() : async [(StastisticsGameID, BasicStats)] {
    return _onValidation;
  };

  public shared func setGameValid(StastisticsGameID : StastisticsGameID) : async Bool {
    switch (onValidation.get(StastisticsGameID)) {
      case (null) {
        return false;
      };
      case (?_bs) {
        onValidation.delete(StastisticsGameID);
        basicStats.put(StastisticsGameID, _bs);
        return true;
      };
    };
  };

  //Game validator
  func maxPlausibleScore(timeInSeconds : Float) : Float {
    let maxScoreRate : Float = 550000.0 / (5.0 * 60.0);
    let maxPlausibleScore : Float = maxScoreRate * timeInSeconds;
    return maxPlausibleScore;
  };
  /**
  func validateEnergyBalance(timeInSeconds : Float, energySpent : Float) : Bool {
    let energyGenerated : Float = 30.0 + (0.5 * timeInSeconds);
    return energyGenerated == energySpent;
  };

  func validateEfficiency(score : Float, energySpent : Float, efficiencyThreshold : Float) : Bool {
    let efficiency : Float = score / energySpent;
    return efficiency <= efficiencyThreshold;
  };
**/
  public shared query func validateGame(timeInSeconds : Float, _energySpent : Float, score : Float, _efficiencyThreshold : Float) : async (Bool, Text) {
    let maxScore : Float = maxPlausibleScore(timeInSeconds);
    let isScoreValid : Bool = score <= maxScore;
    //let isEnergyBalanceValid : Bool  = validateEnergyBalance(timeInSeconds, energySpent);
    //let isEfficiencyValid    : Bool  = validateEfficiency(score, energySpent, efficiencyThreshold);
    if (isScoreValid /* and isEnergyBalanceValid and isEfficiencyValid*/) {
      return (true, "Game is valid");
    } else {
      // onValidation.put(StastisticsGameID, _basicStats);
      if (isScoreValid == false) {
        return (false, "Score is not valid");
        // } else if(isEnergyBalanceValid == false){
        //     return (false, "Energy balance is not valid");
        // } else if(isEfficiencyValid == false){
        //     return (false, "Efficiency is not valid");
      } else {
        return (false, "Game is not valid");
      };
    };
  };

  //Rewards
  private stable var rewardID : Nat = 1;
  private var ONE_HOUR : Nat64 = 60 * 60 * 1_000_000_000; // 24 hours in nanoseconds
  private var NULL_PRINCIPAL : Principal = Principal.fromText("aaaaa-aa");
  private var ANON_PRINCIPAL : Principal = Principal.fromText("2vxsx-fae");
  private stable var _activeRewards : [(Nat, Reward)] = [];
  var activeRewards : HashMap.HashMap<Nat, Reward> = HashMap.fromIter(_activeRewards.vals(), 0, _natEqual, _natHash);
  private stable var _rewardsUsers : [(PlayerID, [RewardsUser])] = [];
  var rewardsUsers : HashMap.HashMap<PlayerID, [RewardsUser]> = HashMap.fromIter(_rewardsUsers.vals(), 0, Principal.equal, Principal.hash);
  private stable var _finishedRewardsUsers : [(PlayerID, [RewardsUser])] = [];
  var finishedRewardsUsers : HashMap.HashMap<PlayerID, [RewardsUser]> = HashMap.fromIter(_finishedRewardsUsers.vals(), 0, Principal.equal, Principal.hash);
  private stable var _expiredRewardsUsers : [(PlayerID, [RewardsUser])] = [];
  var expiredRewardsUsers : HashMap.HashMap<PlayerID, [RewardsUser]> = HashMap.fromIter(_expiredRewardsUsers.vals(), 0, Principal.equal, Principal.hash);
  private stable var _userLastReward : [(PlayerID, Nat)] = [];
  var userLastReward : HashMap.HashMap<PlayerID, Nat> = HashMap.fromIter(_userLastReward.vals(), 0, Principal.equal, Principal.hash);
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

  public shared query (msg) func getUserReward(_user : PlayerID, _idReward : Nat) : async ?RewardsUser {
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

  //MatchMaking
  private var ONE_SECOND : Nat64 = 1_000_000_000;
  private stable var _matchID : Nat = 1;
  private var inactiveSeconds : Nat64 = 30 * ONE_SECOND;

  private stable var _searching : [(Nat, MatchData)] = [];
  var searching : HashMap.HashMap<Nat, MatchData> = HashMap.fromIter(_searching.vals(), 0, _natEqual, _natHash);

  private stable var _playerStatus : [(UserId, PlayerStatus)] = [];
  var playerStatus : HashMap.HashMap<UserId, PlayerStatus> = HashMap.fromIter(_playerStatus.vals(), 0, Principal.equal, Principal.hash);

  private stable var _inProgress : [(Nat, MatchData)] = [];
  var inProgress : HashMap.HashMap<Nat, MatchData> = HashMap.fromIter(_inProgress.vals(), 0, _natEqual, _natHash);

  private stable var _finishedGames : [(Nat, MatchData)] = [];
  var finishedGames : HashMap.HashMap<Nat, MatchData> = HashMap.fromIter(_finishedGames.vals(), 0, _natEqual, _natHash);

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
              /// Check if the time of expiration have passed already and return false
              if ((_m.player1.lastPlayerActive + inactiveSeconds) < _now) {
                return false;
              };
              let _p : PlayerInfo = _m.player1;
              let _p1 : PlayerInfo = structPlayerActiveNow(_p);
              let _gameData : MatchData = structMatchData(_p1, _m.player2, _m);
              searching.put(_m.gameId, _gameData);
              return true;
            } else {
              let _p : PlayerInfo = switch (_m.player2) {
                case (null) { return false };
                case (?_p) { _p };
              };
              if ((_p.lastPlayerActive + inactiveSeconds) < _now) {
                return false;
              };
              let _p2 : PlayerInfo = structPlayerActiveNow(_p);
              let _gameData : MatchData = structMatchData(_m.player1, ?_p2, _m);
              searching.put(_m.gameId, _gameData);
              return true;
            };
          };
        };
        return false;
      };
    };
  };

  private func structPlayerActiveNow(_p1 : PlayerInfo) : PlayerInfo {
    let _p : PlayerInfo = {
      id = _p1.id;
      elo = _p1.elo;
      matchAccepted = _p1.matchAccepted;
      playerGameData = _p1.playerGameData;
      lastPlayerActive = Nat64.fromIntWrap(Time.now());
      // characterSelected = _p1.characterSelected;
      // deckSavedKeyIds   = _p1.deckSavedKeyIds;
    };
    return _p;
  };

  private func structMatchData(_p1 : PlayerInfo, _p2 : ?PlayerInfo, _m : MatchData) : MatchData {
    let _md : MatchData = {
      gameId = _m.gameId;
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
          let _p : PlayerInfo = _m.player1;
          let _p1 : PlayerInfo = structPlayerActiveNow(_p);
          let _gameData : MatchData = structMatchData(_p1, _m.player2, _m);
          searching.put(_m.gameId, _gameData);
          return true;
        } else {
          let _p : PlayerInfo = switch (_m.player2) {
            case (null) { return false };
            case (?_p) { _p };
          };
          if (player != _p.id) {
            return false;
          };
          if ((_p.lastPlayerActive + inactiveSeconds) < _now) {
            return false;
          };
          let _p2 : PlayerInfo = structPlayerActiveNow(_p);
          let _gameData : MatchData = structMatchData(_m.player1, ?_p2, _m);
          searching.put(_m.gameId, _gameData);
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

  public shared (msg) func getMatchSearching(pgd : Text) : async (SearchStatus, Nat, Text) {
    assert (Principal.notEqual(msg.caller, NULL_PRINCIPAL));
    assert (Principal.notEqual(msg.caller, ANON_PRINCIPAL));
    /// Get Now Time
    let _now : Nat64 = Nat64.fromIntWrap(Time.now());
    let _pELO : Float = await getPlayerElo(msg.caller);
    /// If the player wasn't on a game aleady, check if there's a match available
    //// var _gamesByELO : [MatchData] = getGamesByELOsorted(_pELO, 1000.0); // To-Do: Sort by ELO
    var _gamesByELO : [MatchData] = Iter.toArray(searching.vals());
    for (m in _gamesByELO.vals()) {
      if (m.player2 == null and Principal.notEqual(m.player1.id, msg.caller) and (m.player1.lastPlayerActive + inactiveSeconds) > _now) {
        /// There's a match available, add the player to this match
        let _p2 : PlayerInfo = {
          id = msg.caller;
          elo = _pELO;
          matchAccepted = true; /// Force true for now
          playerGameData = pgd;
          lastPlayerActive = Nat64.fromIntWrap(Time.now());
        };
        let _p1 : PlayerInfo = {
          id = m.player1.id;
          elo = m.player1.elo;
          matchAccepted = true;
          playerGameData = m.player1.playerGameData;
          lastPlayerActive = m.player1.lastPlayerActive;
        };
        let _gameData : MatchData = {
          gameId = m.gameId;
          player1 = _p1;
          player2 = ?_p2;
          status = #Accepted;
        };
        let _p_s : PlayerStatus = {
          status = #Accepted;
          matchID = m.gameId;
        };
        inProgress.put(m.gameId, _gameData);
        let _removedSearching = searching.remove(m.gameId);
        removePlayersFromSearching(m.player1.id, msg.caller, m.gameId);
        playerStatus.put(msg.caller, _p_s);
        playerStatus.put(m.player1.id, _p_s);
        return (#Assigned, _matchID, "Game found");
      };
    };
    /// First we check if the player is already in a match
    switch (playerStatus.get(msg.caller)) {
      case (null) {}; /// Continue with search as this player is not currently in any status
      case (?_p) {
        ///  The player has a status, check which one
        switch (_p.status) {
          case (#Searching) {
            /// The player was already searching, return the status
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
    /// Continue with search as this player is not currently in any status
    _matchID := _matchID + 1;
    let _player : PlayerInfo = {
      id = msg.caller;
      elo = _pELO;
      matchAccepted = false;
      playerGameData = pgd;
      lastPlayerActive = Nat64.fromIntWrap(Time.now());
    };
    let _match : MatchData = {
      gameId = _matchID;
      player1 = _player;
      player2 = null;
      status = #Searching;
    };
    searching.put(_matchID, _match);
    let _ps : PlayerStatus = {
      status = #Searching;
      matchID = _matchID;
    };
    playerStatus.put(msg.caller, _ps);
    return (#Assigned, _matchID, "Lobby created");
  };

  func removePlayersFromSearching(p1 : Principal, p2 : Principal, matchID : Nat) {
    /// Check if player1 or player2 MatchID are different and remove them from the searching list
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
    // public shared(msg) func getMyMatchData() : async (?FullMatchData, Nat){
    switch (playerStatus.get(msg.caller)) {
      case (null) {
        return (null, 0);
      };
      case (?_s) {
        var _m : MatchData = switch (searching.get(_s.matchID)) {
          case (null) {
            switch (inProgress.get(_s.matchID)) {
              case (null) {
                switch (finishedGames.get(_s.matchID)) {
                  case (null) {
                    return (null, 0);
                  };
                  case (?_m) {
                    _m;
                  };
                };
              };
              case (?_m) {
                _m;
              };
            };
          };
          case (?_m) {
            _m;
          };
        };
        let _p : Nat = switch (_m.player1.id == msg.caller) {
          case (true) {
            1;
          };
          case (false) {
            switch (_m.player2) {
              case (null) {
                return (null, 0);
              };
              case (?_p2) {
                2;
              };
            };
          };
        };
        let _p1Name : Text = switch (await getPlayerData(_m.player1.id)) {
          case null {
            "";
          };
          case (?p1) {
            p1.name;
          };
        };
        let _fullPlayer2 : FullPlayerInfo = switch (_m.player2) {
          case null {
            {
              id = Principal.fromText("");
              matchAccepted = false;
              elo = 0;
              playerGameData = "";
              playerName = "";
            };
          };
          case (?p2) {
            let _p2D : ?Player = await getPlayerData(p2.id);
            switch (_p2D) {
              case null {
                {
                  id = p2.id;
                  matchAccepted = p2.matchAccepted;
                  elo = p2.elo;
                  playerGameData = p2.playerGameData;
                  playerName = "";
                };
              };
              case (?_p2D) {
                {
                  id = p2.id;
                  matchAccepted = p2.matchAccepted;
                  elo = p2.elo;
                  playerGameData = p2.playerGameData;
                  playerName = _p2D.name;
                };
              };
            };
          };
        };
        let _fullPlayer1 : FullPlayerInfo = {
          id = _m.player1.id;
          matchAccepted = _m.player1.matchAccepted;
          elo = _m.player1.elo;
          playerGameData = _m.player1.playerGameData;
          playerName = _p1Name;
        };
        let fm : FullMatchData = {
          gameId = _m.gameId;
          player1 = _fullPlayer1;
          player2 = ?_fullPlayer2;
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
};
