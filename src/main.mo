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
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Types "Types";
import Utils "Utils";
import TypesICRC7 "/icrc7/types";
import TypesICRC1 "/icrc1/Types";
import Validator "Validator";

shared actor class Cosmicrafts() {

  private stable var _cosmicraftsPrincipal : Principal = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai");

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
  public type OverallGamesWithFaction = Types.OverallGamesWithFaction;
  public type OverallGamesWithGameMode = Types.OverallGamesWithGameMode;
  public type OverallGamesWithCharacter = Types.OverallGamesWithCharacter;

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

  //ICRC
  public type TokenID = Types.TokenId;

  // Utils
  func _natEqual(a : Nat, b : Nat) : Bool {
    return a == b;
  };

  func _natHash(a: Nat): Hash.Hash {
    return Utils._natHash(a);
  };

  // Players
  private stable var _players: [(PlayerId, Player)] = [];
  var players: HashMap.HashMap<PlayerId, Player> = HashMap.fromIter(_players.vals(), 0, Principal.equal, Principal.hash);

  // Function to register a new player
  public shared ({ caller: PlayerId }) func registerPlayer(username: Username, avatar: AvatarID) : async (Bool, PlayerId) {
    let PlayerId = caller;
    switch (players.get(PlayerId)) {
      case (null) {
        let registrationDate = Time.now();
        let newPlayer: Player = {
          id = PlayerId;
          username = username;
          avatar = avatar;
          description = "";
          registrationDate = registrationDate;
          level = 1;
          elo = 1200;
          friends = [];
        };
        players.put(PlayerId, newPlayer);

        // Initialize player stats
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
        playerGamesStats.put(PlayerId, initialStats);

        return (true, PlayerId);
      };
      case (?_) {
        return (false, PlayerId); // User already exists
      };
    };
  };

  // Function to update username
  public shared ({ caller: PlayerId }) func updateUsername(username: Username) : async (Bool, PlayerId) {
    let PlayerId = caller;
    switch (players.get(PlayerId)) {
      case (null) {
        return (false, PlayerId); // User record does not exist
      };
      case (?player) {
        let updatedPlayer: Player = {
          id = player.id;
          username = username;
          avatar = player.avatar;
          description = player.description;
          registrationDate = player.registrationDate;
          level = player.level;
          elo = player.elo;
          friends = player.friends;
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
                    };
                    players.put(playerId, updatedPlayer);
                    return (true, "Friend added successfully");
                };
            };
        };
    };
};

  // convert float xp into level nat
  private func calculateLevel(xp: Float) : Nat {
    let levelFloat = if (xp < 100.0) 1.0 else Float.trunc(Float.log(xp / 100.0) / Float.log(2.0)) + 1.0;
    let levelInt = Float.toInt(levelFloat);
    let levelNat64 = Nat64.fromIntWrap(levelInt);
    return Nat64.toNat(levelNat64);
  };

  // Statistics
  private stable var _basicStats: [(MatchID, BasicStats)] = [];
  var basicStats: HashMap.HashMap<MatchID, BasicStats> = HashMap.fromIter(_basicStats.vals(), 0, _natEqual, _natHash);

  private stable var _playerGamesStats: [(PlayerId, PlayerGamesStats)] = [];
  var playerGamesStats: HashMap.HashMap<PlayerId, PlayerGamesStats> = HashMap.fromIter(_playerGamesStats.vals(), 0, Principal.equal, Principal.hash);

  private stable var _onValidation: [(MatchID, BasicStats)] = [];
  var onValidation: HashMap.HashMap<MatchID, BasicStats> = HashMap.fromIter(_onValidation.vals(), 0, _natEqual, _natHash);

  private stable var _countedMatches: [(MatchID, Bool)] = [];
  var countedMatches: HashMap.HashMap<MatchID, Bool> = HashMap.fromIter(_countedMatches.vals(), 0, _natEqual, _natHash);


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

  private func setGameOver(caller: Principal) : async (Bool, Bool, ?Principal) {
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

  private func updatePlayerELO(PlayerId : PlayerId, won : Nat, otherPlayerId : ?PlayerId) : async Bool {
    switch (otherPlayerId) {
        case (null) {
            return false;
        };
        case (?otherPlayer) {
            // Get both players' ELO
            var _p1Elo : Float = await getPlayerElo(PlayerId);
            let _p2Elo : Float = await getPlayerElo(otherPlayer);

            // Base K-Factor for ELO changes
            let baseKFactor : Float = 32.0;

            // Determine win and loss factors based on player's ELO
            let winFactor : Float = if (_p1Elo < 1400.0) 2.0
                                    else if (_p1Elo < 1800.0) 1.75
                                    else if (_p1Elo < 2200.0) 1.5
                                    else if (_p1Elo < 2600.0) 1.25
                                    else 1.0;

            let lossFactor : Float = if (_p1Elo < 1400.0) 0.1
                                     else if (_p1Elo < 1800.0) 0.5
                                     else if (_p1Elo < 2200.0) 1.0
                                     else if (_p1Elo < 2600.0) 1.25
                                     else 2.0;

            // Calculate expected win probability
            let _p1Expected : Float = 1 / (1 + Float.pow(10, (_p2Elo - _p1Elo) / 400));
            let _p2Expected : Float = 1 / (1 + Float.pow(10, (_p1Elo - _p2Elo) / 400));

            // Calculate ELO change
            let pointChange : Float = if (won == 1) 
                                      baseKFactor * winFactor * (1 - _p1Expected)
                                      else 
                                      -baseKFactor * lossFactor * _p1Expected;

            let _elo : Float = _p1Elo + pointChange;

            let _updated = await updateELOonPlayer(PlayerId, _elo);

            return _updated;
        };
    };
};

  private func updateELOonPlayer(playerId : Principal, newELO : Float) : async Bool {
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
              };
              players.put(playerId, updatedPlayer);
              return true;
          };
      };
  };

// Function to update player stats after a match
public shared (msg) func saveFinishedGame(matchID: MatchID, _playerStats: {
    secRemaining: Float;
    energyGenerated: Float;
    damageDealt: Float;
    wonGame: Bool;
    botMode: Nat;
    deploys: Float;
    damageTaken: Float;
    damageCritic: Float;
    damageEvaded: Float;
    energyChargeRate: Float;
    faction: Nat;
    energyUsed: Float;
    gameMode: Nat;
    energyWasted: Float;
    xpEarned: Float;
    characterID: Nat;
    botDifficulty: Nat;
    kills: Float;
}) : async (Bool, Text) {
    var _txt: Text = "";

    // Create a new PlayerStats record with playerId set to msg.caller
    let playerStats = {
        secRemaining = _playerStats.secRemaining;
        energyGenerated = _playerStats.energyGenerated;
        damageDealt = _playerStats.damageDealt;
        wonGame = _playerStats.wonGame;
        playerId = msg.caller;  // Set the playerId to the caller's principal
        botMode = _playerStats.botMode;
        deploys = _playerStats.deploys;
        damageTaken = _playerStats.damageTaken;
        damageCritic = _playerStats.damageCritic;
        damageEvaded = _playerStats.damageEvaded;
        energyChargeRate = _playerStats.energyChargeRate;
        faction = _playerStats.faction;
        energyUsed = _playerStats.energyUsed;
        gameMode = _playerStats.gameMode;
        energyWasted = _playerStats.energyWasted;
        xpEarned = _playerStats.xpEarned;
        characterID = _playerStats.characterID;
        botDifficulty = _playerStats.botDifficulty;
        kills = _playerStats.kills;
    };

    // Check if the match exists in basicStats
    let isExistingMatch = switch (basicStats.get(matchID)) {
        case (null) { false };
        case (?_) { true };
    };

    // Set the game as over
    let endingGame: (Bool, Bool, ?Principal) = await setGameOver(msg.caller);

    // Validate if the caller is part of the match
    let isPartOfMatch = await isCallerPartOfMatch(matchID, msg.caller);
    if (not isPartOfMatch) {
        return (false, "You are not part of this match.");
    };

    if (isExistingMatch) {
        // Check if the principal has already submitted stats
        switch (basicStats.get(matchID)) {
            case (null) {
                return (false, "Unexpected error: Match not found");
            };
            case (?_bs) {
                for (ps in _bs.playerStats.vals()) {
                    if (ps.playerId == msg.caller) {
                        return (false, "You have already submitted stats for this match.");
                    };
                };
            };
        };
    };

    if (not isExistingMatch) {
        // Save the basic stats for a new match
        let newBasicStats: BasicStats = {
            playerStats = [playerStats];
        };
        basicStats.put(matchID, newBasicStats);

        // Validate the game
        let (_gameValid, validationMsg) = Validator.validateGame(300.0 - playerStats.secRemaining, playerStats.xpEarned);
        if (not _gameValid) {
            onValidation.put(matchID, newBasicStats);
            return (false, validationMsg);
        };

        // Update player stats
        let _winner = if (playerStats.wonGame) 1 else 0;
        let _looser = if (not playerStats.wonGame) 1 else 0;
        let _elo: Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);
        let _progressRewardsBuffer = Buffer.Buffer<RewardProgress>(1);
        _progressRewardsBuffer.add({ rewardType = #GamesCompleted; progress = 1; });
        if (playerStats.wonGame) {
            _progressRewardsBuffer.add({ rewardType = #GamesWon; progress = 1; });
        };
        let _progressRewards = Buffer.toArray(_progressRewardsBuffer);
        let _progressAdded = await addProgressToRewards(msg.caller, _progressRewards);
        _txt := _progressAdded.1;

        // Update or create player game stats
        updatePlayerGameStats(msg.caller, playerStats, _winner, _looser);

        // Update overall stats
        updateOverallStats(matchID, playerStats);

        // Update player level
        let playerOpt = players.get(msg.caller);
        switch (playerOpt) {
            case (?player) {
                let updatedPlayer: Player = {
                    id = player.id;
                    username = player.username;
                    avatar = player.avatar;
                    description = player.description;
                    registrationDate = player.registrationDate;
                    level = calculateLevel(playerStats.xpEarned);
                    elo = player.elo;
                    friends = player.friends;
                };
                players.put(msg.caller, updatedPlayer);
            };
            case (null) {};
        };

        return (true, "Game saved");
    } else {
        // If the match was already saved, add the new player's stats
        switch (basicStats.get(matchID)) {
            case (null) {
                return (false, "Unexpected error: Match not found");
            };
            case (?_bs) {
                let updatedPlayerStatsBuffer = Buffer.Buffer<PlayerStats>(_bs.playerStats.size() + 1);
                for (ps in _bs.playerStats.vals()) {
                    updatedPlayerStatsBuffer.add(ps);
                };
                updatedPlayerStatsBuffer.add(playerStats);
                let updatedPlayerStats = Buffer.toArray(updatedPlayerStatsBuffer);
                let updatedBasicStats: BasicStats = { playerStats = updatedPlayerStats };
                basicStats.put(matchID, updatedBasicStats);

                // Validate the game
                let (_gameValid, validationMsg) = Validator.validateGame(300.0 - playerStats.secRemaining, playerStats.xpEarned);
                if (not _gameValid) {
                    onValidation.put(matchID, updatedBasicStats);
                    return (false, validationMsg);
                };

                // Update player stats
                let _winner = if (playerStats.wonGame) 1 else 0;
                let _looser = if (not playerStats.wonGame) 1 else 0;
                let _elo: Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);
                let _progressRewardsBuffer = Buffer.Buffer<RewardProgress>(1);
                _progressRewardsBuffer.add({ rewardType = #GamesCompleted; progress = 1; });
                if (playerStats.wonGame) {
                    _progressRewardsBuffer.add({ rewardType = #GamesWon; progress = 1; });
                };
                let _progressRewards = Buffer.toArray(_progressRewardsBuffer);
                let _progressAdded = await addProgressToRewards(msg.caller, _progressRewards);
                _txt := _progressAdded.1;

                // Update or create player game stats
                updatePlayerGameStats(msg.caller, playerStats, _winner, _looser);

                // Update overall stats
                updateOverallStats(matchID, playerStats);

                // Update player level
                let playerOpt = players.get(msg.caller);
                switch (playerOpt) {
                    case (?player) {
                        let updatedPlayer: Player = {
                            id = player.id;
                            username = player.username;
                            avatar = player.avatar;
                            description = player.description;
                            registrationDate = player.registrationDate;
                            level = calculateLevel(playerStats.xpEarned);
                            elo = player.elo;
                            friends = player.friends;
                        };
                        players.put(msg.caller, updatedPlayer);
                    };
                    case (null) {};
                };

                return (true, _txt # " - Game saved");
            };
        };
    };
};

// Helper function to check if the caller is part of the match
private func isCallerPartOfMatch(matchID: MatchID, caller: Principal) : async Bool {
    let matchParticipants = await getMatchParticipants(matchID);
    switch (matchParticipants) {
        case (null) { return false };
        case (?matchData) {
            if (matchData.0 == caller) {
                return true;
            };
            switch (matchData.1) {
                case (?player2) {
                    if (player2 == caller) {
                        return true;
                    };
                };
                case (null) {};
            };
            return false;
        };
    }
};


// Function to update player stats
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
                totalGamesWithFaction = [{ factionID = _playerStats.faction; gamesPlayed = 1; gamesWon = _winner; }];
                totalGamesGameMode = [{ gameModeID = _playerStats.gameMode; gamesPlayed = 1; gamesWon = _winner; }];
                totalGamesWithCharacter = [{ characterID = _playerStats.characterID; gamesPlayed = 1; gamesWon = _winner; }];
            };
            playerGamesStats.put(playerId, _gs);
        };
        case (?_bs) {
            let _gamesWithFactionBuffer = Buffer.Buffer<GamesWithFaction>(_bs.totalGamesWithFaction.size());
            for (gf in _bs.totalGamesWithFaction.vals()) {
                if (gf.factionID == _playerStats.faction) {
                    _gamesWithFactionBuffer.add({ gamesPlayed = gf.gamesPlayed + 1; factionID = gf.factionID; gamesWon = gf.gamesWon + _winner; });
                } else {
                    _gamesWithFactionBuffer.add(gf);
                };
            };
            let _gamesWithFaction = Buffer.toArray(_gamesWithFactionBuffer);

            let _gamesWithGameModeBuffer = Buffer.Buffer<GamesWithGameMode>(_bs.totalGamesGameMode.size());
            for (gm in _bs.totalGamesGameMode.vals()) {
                if (gm.gameModeID == _playerStats.gameMode) {
                    _gamesWithGameModeBuffer.add({ gamesPlayed = gm.gamesPlayed + 1; gameModeID = gm.gameModeID; gamesWon = gm.gamesWon + _winner; });
                } else {
                    _gamesWithGameModeBuffer.add(gm);
                };
            };
            let _gamesWithGameMode = Buffer.toArray(_gamesWithGameModeBuffer);

            let _totalGamesWithCharacterBuffer = Buffer.Buffer<GamesWithCharacter>(_bs.totalGamesWithCharacter.size());
            for (gc in _bs.totalGamesWithCharacter.vals()) {
                if (gc.characterID == _playerStats.characterID) {
                    _totalGamesWithCharacterBuffer.add({ gamesPlayed = gc.gamesPlayed + 1; characterID = gc.characterID; gamesWon = gc.gamesWon + _winner; });
                } else {
                    _totalGamesWithCharacterBuffer.add(gc);
                };
            };
            let _totalGamesWithCharacter = Buffer.toArray(_totalGamesWithCharacterBuffer);

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
private func updateOverallStats(matchID: MatchID, _playerStats: PlayerStats) {
    // Ensure the match is counted only once
    switch (countedMatches.get(matchID)) {
        case (?_) {
            return; // already counted match
        };
        case (null) {
            countedMatches.put(matchID, true);
        };
    };

    let _totalGamesWithFactionBuffer = Buffer.Buffer<OverallGamesWithFaction>(overallStats.totalGamesWithFaction.size());
    var factionFound = false;
    for (gf in overallStats.totalGamesWithFaction.vals()) {
        if (gf.factionID == _playerStats.faction) {
            _totalGamesWithFactionBuffer.add({
                gamesPlayed = gf.gamesPlayed + 1;
                factionID = gf.factionID;
            });
            factionFound := true;
        } else {
            _totalGamesWithFactionBuffer.add(gf);
        };
    };
    if (not factionFound) {
        _totalGamesWithFactionBuffer.add({
            gamesPlayed = 1;
            factionID = _playerStats.faction;
        });
    };
    let _totalGamesWithFaction = Buffer.toArray(_totalGamesWithFactionBuffer);

    let _totalGamesWithGameModeBuffer = Buffer.Buffer<OverallGamesWithGameMode>(overallStats.totalGamesGameMode.size());
    var gameModeFound = false;
    for (gm in overallStats.totalGamesGameMode.vals()) {
        if (gm.gameModeID == _playerStats.gameMode) {
            _totalGamesWithGameModeBuffer.add({
                gamesPlayed = gm.gamesPlayed + 1;
                gameModeID = gm.gameModeID;
            });
            gameModeFound := true;
        } else {
            _totalGamesWithGameModeBuffer.add(gm);
        };
    };
    if (not gameModeFound) {
        _totalGamesWithGameModeBuffer.add({
            gamesPlayed = 1;
            gameModeID = _playerStats.gameMode;
        });
    };
    let _totalGamesWithGameMode = Buffer.toArray(_totalGamesWithGameModeBuffer);

    let _totalGamesWithCharacterBuffer = Buffer.Buffer<OverallGamesWithCharacter>(overallStats.totalGamesWithCharacter.size());
    var characterFound = false;
    for (gc in overallStats.totalGamesWithCharacter.vals()) {
        if (gc.characterID == _playerStats.characterID) {
            _totalGamesWithCharacterBuffer.add({
                gamesPlayed = gc.gamesPlayed + 1;
                characterID = gc.characterID;
            });
            characterFound := true;
        } else {
            _totalGamesWithCharacterBuffer.add(gc);
        };
    };
    if (not characterFound) {
        _totalGamesWithCharacterBuffer.add({
            gamesPlayed = 1;
            characterID = _playerStats.characterID;
        });
    };
    let _totalGamesWithCharacter = Buffer.toArray(_totalGamesWithCharacterBuffer);

    let maxGameTime: Float = 300.0; // 5 minutes in seconds
    let timePlayed: Float = maxGameTime - _playerStats.secRemaining;

    let _os: OverallStats = {
        totalGamesPlayed = overallStats.totalGamesPlayed + 1;
        totalGamesSP = if (_playerStats.gameMode == 2) overallStats.totalGamesSP + 1 else overallStats.totalGamesSP;
        totalGamesMP = if (_playerStats.gameMode == 1) overallStats.totalGamesMP + 1 else overallStats.totalGamesMP;
        totalDamageDealt = overallStats.totalDamageDealt + _playerStats.damageDealt;
        totalTimePlayed = overallStats.totalTimePlayed + timePlayed;
        totalKills = overallStats.totalKills + _playerStats.kills;
        totalEnergyUsed = overallStats.totalEnergyUsed + _playerStats.energyUsed;
        totalEnergyGenerated = overallStats.totalEnergyGenerated + _playerStats.energyGenerated;
        totalEnergyWasted = overallStats.totalEnergyWasted + _playerStats.energyWasted;
        totalGamesWithFaction = _totalGamesWithFaction;
        totalGamesGameMode = _totalGamesWithGameMode;
        totalGamesWithCharacter = _totalGamesWithCharacter;
        totalXpEarned = overallStats.totalXpEarned + _playerStats.xpEarned;
    };
    overallStats := _os;
};

  // MatchMaking
  private var ONE_SECOND : Nat64 = 1_000_000_000;
  private stable var _matchID : Nat = 0;
  private var inactiveSeconds : Nat64 = 30 * ONE_SECOND;

  private stable var _searching : [(MatchID, MatchData)] = [];
  var searching : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_searching.vals(), 0, _natEqual, _natHash);

  private stable var _playerStatus : [(PlayerId, MMPlayerStatus)] = [];
  var playerStatus : HashMap.HashMap<PlayerId, MMPlayerStatus> = HashMap.fromIter(_playerStatus.vals(), 0, Principal.equal, Principal.hash);

  private stable var _inProgress : [(MatchID, MatchData)] = [];
  var inProgress : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_inProgress.vals(), 0, _natEqual, _natHash);

  private stable var _finishedGames : [(MatchID, MatchData)] = [];
  var finishedGames : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_finishedGames.vals(), 0, _natEqual, _natHash);

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
              let username = switch (await getProfile(msg.caller)) {
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
      let username = switch (await getProfile(msg.caller)) {
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

  // QPlayers

  // Full User Profile with statistics and friends
  public query func getFullUserProfile(player: PlayerId) : async ?(Player, PlayerGamesStats, AverageStats) {
    switch (players.get(player)) {
      case (null) { return null; };
      case (?playerData) {
        let playerStatsOpt = playerGamesStats.get(player);
        let playerStats = switch (playerStatsOpt) {
          case (null) { 
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
            initialStats;
          };
          case (?stats) { stats; };
        };

        let gamesPlayed = Float.fromInt64(Int64.fromNat64(Nat64.fromNat(playerStats.gamesPlayed)));
        let averageStats: AverageStats = {
          averageEnergyGenerated = if (gamesPlayed == 0) 0 else playerStats.energyGenerated / gamesPlayed;
          averageEnergyUsed = if (gamesPlayed == 0) 0 else playerStats.energyUsed / gamesPlayed;
          averageEnergyWasted = if (gamesPlayed == 0) 0 else playerStats.energyWasted / gamesPlayed;
          averageDamageDealt = if (gamesPlayed == 0) 0 else playerStats.totalDamageDealt / gamesPlayed;
          averageKills = if (gamesPlayed == 0) 0 else playerStats.totalDamageDealt / gamesPlayed;
          averageXpEarned = if (gamesPlayed == 0) 0 else playerStats.totalXpEarned / gamesPlayed;
        };

        return ?(playerData, playerStats, averageStats);
      };
    };
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

  // self query Gets a list of friend's principals
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

  // Self query to get user profile
  public shared (msg) func getMyProfile() : async ?Player {
    return players.get(msg.caller);
  };

  // Function to get another user profile
  public query func getProfile(player: PlayerId) : async ?Player {
    return players.get(player);
  };

  // List all players
  public query func getAllPlayers() : async [Player] {
    return Iter.toArray(players.vals());
  };

  // QStatistics
  public query func getPlayerStats(player: PlayerId) : async ?PlayerGamesStats {
    return playerGamesStats.get(player);
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

  // QMatchmaking
  public query func getAllSearching() : async [MatchData] {
    let _searchingList = Buffer.Buffer<MatchData>(searching.size());
    for (m in searching.vals()) {
        _searchingList.add(m);
    };
    return Buffer.toArray(_searchingList);
  };

   public query (msg) func isGameMatched() : async (Bool, Text) {
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

  public query func getMatchParticipants(matchID: MatchID) : async ?(Principal, ?Principal) {
    switch (finishedGames.get(matchID)) {
        case (null) {
            switch (inProgress.get(matchID)) {
                case (null) {
                    switch (searching.get(matchID)) {
                        case (null) { return null };
                        case (?matchData) {
                            let player2Id = switch (matchData.player2) {
                                case (null) { null };
                                case (?p) { ?p.id };
                            };
                            return ?(matchData.player1.id, player2Id);
                        };
                    };
                };
                case (?matchData) {
                    let player2Id = switch (matchData.player2) {
                        case (null) { null };
                        case (?p) { ?p.id };
                    };
                    return ?(matchData.player1.id, player2Id);
                };
            };
        };
        case (?matchData) {
            let player2Id = switch (matchData.player2) {
                case (null) { null };
                case (?p) { ?p.id };
            };
            return ?(matchData.player1.id, player2Id);
        };
    }
};

  // For loading match screen
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

              let _p1Data = await getProfile(_m.player1.id);
              let _p1Name = switch (_p1Data) { case (null) ""; case (?p1) p1.username; };
              let _p1Avatar = switch (_p1Data) { case (null) 0; case (?p1) p1.avatar; };
              let _p1Level = switch (_p1Data) { case (null) 0; case (?p1) p1.level; };

              let _fullPlayer2 = switch (_m.player2) {
                  case null null;
                  case (?p2) {
                      let _p2D = await getProfile(p2.id);
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

  // QMatch History
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

  // Basic Stats sent for a MatchID
  public shared query func getMatchStats(MatchID : MatchID) : async ?BasicStats {
    return basicStats.get(MatchID);
  };

  // Basic Stats + User Profiles for a MatchID
  public query func getMatchDetails(matchID: MatchID) : async ?(MatchData, [(Player, PlayerGamesStats)]) {
    let matchDataOpt = switch (finishedGames.get(matchID)) {
      case (null) {
        switch (inProgress.get(matchID)) {
          case (null) {
            switch (searching.get(matchID)) {
              case (null) { return null; };
              case (?matchData) { ?matchData; };
            };
          };
          case (?matchData) { ?matchData; };
        };
      };
      case (?matchData) { ?matchData; };
    };

    switch (matchDataOpt) {
      case (null) { return null; };
      case (?matchData) {
        let playerStats = Buffer.Buffer<(Player, PlayerGamesStats)>(2); // Assuming max 2 players

        switch (players.get(matchData.player1.id)) {
          case (null) {};
          case (?player1Data) {
            switch (playerGamesStats.get(matchData.player1.id)) {
              case (null) {};
              case (?player1Stats) {
                playerStats.add((player1Data, player1Stats));
              };
            };
          };
        };

        switch (matchData.player2) {
          case (null) {};
          case (?player2Info) {
            switch (players.get(player2Info.id)) {
              case (null) {};
              case (?player2Data) {
                switch (playerGamesStats.get(player2Info.id)) {
                  case (null) {};
                  case (?player2Stats) {
                    playerStats.add((player2Data, player2Stats));
                  };
                };
              };
            };
          };
        };

        return ?(matchData, Buffer.toArray(playerStats));
      };
    };
  };

  public query func getMatchHistoryByPrincipal(player: PlayerId): async [(MatchID, ?BasicStats)] {
      let buffer = Buffer.Buffer<(MatchID, ?BasicStats)>(0);
      for ((matchID, matchData) in finishedGames.entries()) {
          if (matchData.player1.id == player) {
              let matchStats = basicStats.get(matchID);
              buffer.add((matchID, matchStats));
          } else {
              switch (matchData.player2) {
                  case (null) {};
                  case (?p2) {
                      if (p2.id == player) {
                          let matchStats = basicStats.get(matchID);
                          buffer.add((matchID, matchStats));
                      }
                  };
              }
          }
      };
      return Buffer.toArray(buffer);
  };
  
  public query func test(playerId: PlayerId) : async ?{
    username: Username;
    level: Level;
    elo: Float;
    xp: Float;
    gamesWon: Nat;
    gamesLost: Nat;
    } {
        // Retrieve player details
        let playerOpt = players.get(playerId);
        let playerStatsOpt = playerGamesStats.get(playerId);

        switch (playerOpt, playerStatsOpt) {
            case (null, _) {
                // Player does not exist
                return null;
            };
            case (_, null) {
                // Player stats do not exist
                return null;
            };
            case (?player, ?stats) {
                // Gather the required data
                let result = {
                    username = player.username;
                    level = player.level;
                    elo = player.elo;
                    xp = stats.totalXpEarned;
                    gamesWon = stats.gamesWon;
                    gamesLost = stats.gamesLost;
                };

                return ?result;
            };
        };
    };

    public query func getCosmicraftsStats() : async OverallStats {
        return overallStats;
    };

// ICRCs
type Result <S, E> = Result.Result<S, E>;

let shards: ICRC1Interface = actor("bw4dl-smaaa-aaaaa-qaacq-cai") : ICRC1Interface;

let flux: ICRC1Interface = actor("b77ix-eeaaa-aaaaa-qaada-cai") : ICRC1Interface;

let gameNFTs: ICRC7Interface = actor("be2us-64aaa-aaaaa-qaabq-cai") : ICRC7Interface;

let chests: ICRC7Interface = actor("br5f7-7uaaa-aaaaa-qaaca-cai") : ICRC7Interface;

// private stable var nftID : TokenID = 0;

// private stable var chestID : TokenID = 0;


// ICRC 1
type ICRC1Interface = actor {
    icrc1_name: shared () -> async Text;
    icrc1_symbol: shared () -> async Text;
    icrc1_decimals: shared () -> async Nat8;
    icrc1_fee: shared () -> async TypesICRC1.Balance;
    icrc1_metadata: shared () -> async [TypesICRC1.MetaDatum];
    icrc1_total_supply: shared () -> async TypesICRC1.Balance;
    icrc1_minting_account: shared () -> async ?TypesICRC1.Account;
    icrc1_balance_of: shared (args: TypesICRC1.Account) -> async TypesICRC1.Balance;
    icrc1_supported_standards: shared () -> async [TypesICRC1.SupportedStandard];
    icrc1_transfer: shared (args: TypesICRC1.TransferArgs) -> async TypesICRC1.TransferResult;
    icrc1_pay_for_transaction: shared (args: TypesICRC1.TransferArgs, from: Principal) -> async TypesICRC1.TransferResult;
    mint: shared (args: TypesICRC1.Mint) -> async TypesICRC1.TransferResult;
    burn: shared (args: TypesICRC1.BurnArgs) -> async TypesICRC1.TransferResult;
    get_transactions: shared (req: TypesICRC1.GetTransactionsRequest) -> async TypesICRC1.GetTransactionsResponse;
    get_transaction: shared (i: TypesICRC1.TxIndex) -> async ?TypesICRC1.Transaction;
    deposit_cycles: shared () -> async ();
};

 // ICRC 7
type ICRC7Interface = actor {
    icrc7_collection_metadata: shared () -> async TypesICRC7.CollectionMetadata;
    icrc7_name: shared () -> async Text;
    icrc7_symbol: shared () -> async Text;
    icrc7_royalties: shared () -> async ?Nat16;
    icrc7_royalty_recipient: shared () -> async ?TypesICRC7.Account;
    icrc7_description: shared () -> async ?Text;
    icrc7_image: shared () -> async ?Blob;
    icrc7_total_supply: shared () -> async Nat;
    icrc7_supply_cap: shared () -> async ?Nat;
    icrc7_metadata: shared (tokenId: TypesICRC7.TokenId) -> async TypesICRC7.MetadataResult;
    icrc7_owner_of: shared (tokenId: TypesICRC7.TokenId) -> async TypesICRC7.OwnerResult;
    icrc7_balance_of: shared (account: TypesICRC7.Account) -> async TypesICRC7.BalanceResult;
    icrc7_tokens_of: shared (account: TypesICRC7.Account) -> async TypesICRC7.TokensOfResult;
    icrc7_transfer: shared (transferArgs: TypesICRC7.TransferArgs) -> async TypesICRC7.TransferReceipt;
    icrc7_approve: shared (approvalArgs: TypesICRC7.ApprovalArgs) -> async TypesICRC7.ApprovalReceipt;
    icrc7_supported_standards: shared () -> async [TypesICRC7.SupportedStandard];
    mint: shared (mintArgs: TypesICRC7.MintArgs) -> async TypesICRC7.MintReceipt;
    upgradeNFT: shared (upgradeArgs: TypesICRC7.UpgradeArgs) -> async TypesICRC7.UpgradeReceipt;
    mintDeck: shared (deck: [TypesICRC7.MintArgs]) -> async TypesICRC7.MintReceipt;
    get_transactions: shared (getTransactionsArgs: TypesICRC7.GetTransactionsArgs) -> async TypesICRC7.GetTransactionsResult;
    openChest: shared (args: TypesICRC7.OpenArgs) -> async TypesICRC7.OpenReceipt;
    updateChestMetadata: shared (updateArgs: TypesICRC7.UpdateArgs) -> async TypesICRC7.Result<TypesICRC7.TokenId, TypesICRC7.UpdateError>;
};

// GameNFTs

// Mint deck with 8 units and random rarity within a range provided
public shared({ caller }) func mintDeck() : async (Bool, Text) {
    let units = Utils.initDeck();

    var _deck = Buffer.Buffer<TypesICRC7.MintArgs>(8);

    for (i in Iter.range(0, 7)) {
        let (name, damage, hp, rarity) = units[i];
        let uuid = await Utils.generateUUID64();
        let _mintArgs: TypesICRC7.MintArgs = {
            to = { owner = caller; subaccount = null };
            token_id = uuid;
            metadata = Utils.getBaseMetadataWithAttributes(rarity, i + 1, name, damage, hp);
        };
        _deck.add(_mintArgs);
    };

    let mintResult = await gameNFTs.mintDeck(Buffer.toArray(_deck));
    switch (mintResult) {
        case (#Ok(_transactionID)) {
            return (true, "Deck minted. # NFTs: " # Nat.toText(_transactionID));
        };
        case (#Err(_e)) {
            switch (_e) {
                case (#AlreadyExistTokenId) {
                    return (false, "Deck mint failed: Token ID already exists");
                };
                case (#GenericError(_g)) {
                    return (false, "Deck mint failed: GenericError: " # _g.message);
                };
                case (#InvalidRecipient) {
                    return (false, "Deck mint failed: InvalidRecipient");
                };
                case (#Unauthorized) {
                    return (false, "Deck mint failed: Unauthorized");
                };
                case (#SupplyCapOverflow) {
                    return (false, "Deck mint failed: SupplyCapOverflow");
                };
            };
        };
    };
};

public shared(msg) func upgradeNFT(nftID: TokenID) : async (Bool, Text) {
    // Initiate metadata retrieval in the background
    let metadataFuture = async { await gameNFTs.icrc7_metadata(nftID) };

    // Perform ownership check
    let ownerof: TypesICRC7.OwnerResult = await gameNFTs.icrc7_owner_of(nftID);
    let _owner: TypesICRC7.Account = switch (ownerof) {
        case (#Ok(owner)) owner;
        case (#Err(_)) return (false, "{\"success\":false, \"message\":\"NFT not found\"}");
    };
    if (Principal.notEqual(_owner.owner, msg.caller)) {
        return (false, "{\"success\":false, \"message\":\"You do not own this NFT.\"}");
    };

    // Wait for metadata retrieval
    let metadataResult = await metadataFuture;
    let _nftMetadata: [(Text, TypesICRC7.Metadata)] = switch (metadataResult) {
        case (#Ok(metadata)) metadata;
        case (#Err(_)) return (false, "NFT not found");
    };

    // Send the process to the background
    ignore _processUpgrade(nftID, msg.caller, _nftMetadata);

    // Immediate placeholder response to Unity
    let placeholderResponse = "{\"success\":true, \"message\":\"Upgrade initiated\"}";
    return (true, placeholderResponse);
};

// Function to handle the upgrade process in the background
private func _processUpgrade(nftID: TokenID, caller: Principal, _nftMetadata: [(Text, TypesICRC7.Metadata)]): async () {
    // Calculate upgrade cost
    let nftLevel: Nat = Utils.getNFTLevel(_nftMetadata);
    let upgradeCost = Utils.calculateCost(nftLevel);
    let fee = await shards.icrc1_fee();

    // Create transaction arguments for the upgrade cost
    let _transactionsArgs = {
        amount: TypesICRC1.Balance = upgradeCost;
        created_at_time: ?Nat64 = ?Nat64.fromNat(Int.abs(Time.now()));
        fee = ?fee;
        from_subaccount: ?TypesICRC1.Subaccount = null;
        memo: ?Blob = null;
        to: TypesICRC1.Account = { owner = Principal.fromText("aaaaa-aa"); subaccount = null; };
    };

    // Transfer the upgrade cost
    let transfer: TypesICRC1.TransferResult = await shards.icrc1_pay_for_transaction(_transactionsArgs, caller);

    switch (transfer) {
        case (#Ok(_tok)) {
            // Execute the metadata update
            await _executeUpgrade(nftID, caller, _nftMetadata);
            Debug.print("Upgrade successful for NFT ID: " # Nat.toText(nftID) # " by caller: " # Principal.toText(caller));
        };
        case (#Err(_e)) {
            Debug.print("Upgrade cost transfer failed: ");
        };
    };
};

// Function to execute NFT upgrade
private func _executeUpgrade(nftID: TokenID, caller: Principal, _nftMetadata: [(Text, TypesICRC7.Metadata)]): async () {
    // Prepare for upgrade
    let _newArgsBuffer = Buffer.Buffer<(Text, TypesICRC7.Metadata)>(_nftMetadata.size());
    let nftLevel: Nat = Utils.getNFTLevel(_nftMetadata);

    // Update metadata
    for (_md in _nftMetadata.vals()) {
        let _mdKey: Text = _md.0;
        let _mdValue: TypesICRC7.Metadata = _md.1;
        switch (_mdKey) {
            case ("skin") _newArgsBuffer.add(("skin", _mdValue));
            case ("skills") {
                let _upgradedAdvanced = Utils.upgradeAdvancedAttributes(nftLevel, _mdValue);
                _newArgsBuffer.add(("skills", _upgradedAdvanced));
            };
            case ("souls") _newArgsBuffer.add(("souls", _mdValue));
            case ("basic_stats") {
                let _basic_stats = Utils.updateBasicStats(_mdValue);
                _newArgsBuffer.add(("basic_stats", _basic_stats));
            };
            case ("general") _newArgsBuffer.add(("general", _mdValue));
            case (_) _newArgsBuffer.add((_mdKey, _mdValue));
        };
    };

    let _upgradeArgs: TypesICRC7.UpgradeArgs = {
        from = { owner = caller; subaccount = null };
        token_id = nftID;
        metadata = Buffer.toArray(_newArgsBuffer);
        date_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
    };
    let upgrade: TypesICRC7.UpgradeReceipt = await gameNFTs.upgradeNFT(_upgradeArgs);
    switch (upgrade) {
        case (#Ok(_)) Debug.print("NFT upgraded successfully.");
        case (#Err(_e)) Debug.print("NFT upgrade failed:");
    };
};

// Chests
public shared({ caller }) func mintChest(rarity: Nat) : async (Bool, Text) {
    let uuid = await Utils.generateUUID64();
    let _mintArgs: TypesICRC7.MintArgs = {
        to = { owner = caller; subaccount = null };
        token_id = uuid;
        metadata = Utils.getChestMetadata(rarity);
    };
    let mintResult = await chests.mint(_mintArgs);
    switch (mintResult) {
        case (#Ok(_transactionID)) {
            return (true, "NFT minted. Transaction ID: " # Nat.toText(_transactionID));
        };
        case (#Err(_e)) {
            switch (_e) {
                case (#AlreadyExistTokenId) {
                    return (false, "NFT mint failed: Token ID already exists");
                };
                case (#GenericError(_g)) {
                    return (false, "NFT mint failed: GenericError: " # _g.message);
                };
                case (#InvalidRecipient) {
                    return (false, "NFT mint failed: InvalidRecipient");
                };
                case (#Unauthorized) {
                    return (false, "NFT mint failed: Unauthorized");
                };
                case (#SupplyCapOverflow) {
                    return (false, "NFT mint failed: SupplyCapOverflow");
                };
            };
        };
    };
};

public shared({ caller }) func openChest(chestID: Nat): async (Bool, Text) {
    // Perform ownership check
    let ownerof: TypesICRC7.OwnerResult = await chests.icrc7_owner_of(chestID);
    let _owner: TypesICRC7.Account = switch (ownerof) {
        case (#Ok(owner)) owner;
        case (#Err(_)) return (false, "{\"error\":true, \"message\":\"Chest not found\"}");
    };

    if (Principal.notEqual(_owner.owner, caller)) {
        return (false, "{\"error\":true, \"message\":\"Not the owner of the chest\"}");
    };

    // Get tokens to be minted and burn the chest
    let _chestArgs: TypesICRC7.OpenArgs = {
        from = _owner;
        token_id = chestID;
    };

    // Additional checks before calling openChest
    if (Principal.notEqual(_chestArgs.from.owner, caller)) {
        return (false, "{\"error\":true, \"message\":\"Unauthorized: Owner mismatch in _chestArgs\"}");
    };

    let _tokens: TypesICRC7.OpenReceipt = await chests.openChest(_chestArgs);

    var _tokensResults: Text = "";

    // Handle the result of opening the chest
    switch (_tokens) {
        case (#Ok(_t)) {
            // Determine chest rarity based on metadata
            let metadataResult = await chests.icrc7_metadata(chestID);
            let rarity = switch (metadataResult) {
                case (#Ok(metadata)) Utils.getRarityFromMetadata(metadata);
                case (#Err(_)) 1;
            };

            let (shardsAmount, fluxAmount) = Utils.getTokensAmount(rarity);

            // Mint shards tokens
            let _shardsArgs: TypesICRC1.Mint = {
                to = { owner = caller; subaccount = null };
                amount = shardsAmount;
                memo = null;
                created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
            };
            let _shardsMinted: TypesICRC1.TransferResult = await shards.mint(_shardsArgs);

            let shardsResult = switch (_shardsMinted) {
                case (#Ok(_tid)) "{\"token\":\"Shards\", \"transaction_id\": " # Nat.toText(_tid) # ", \"amount\": " # Nat.toText(shardsAmount) # "}";
                case (#Err(_e)) Utils.handleMintError("Shards", _e);
            };

            // Mint flux tokens
            let _fluxArgs: TypesICRC1.Mint = {
                to = { owner = caller; subaccount = null };
                amount = fluxAmount;
                memo = null;
                created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
            };
            let _fluxMinted: TypesICRC1.TransferResult = await flux.mint(_fluxArgs);

            let fluxResult = switch (_fluxMinted) {
                case (#Ok(_tid)) "{\"token\":\"Flux\", \"transaction_id\": " # Nat.toText(_tid) # ", \"amount\": " # Nat.toText(fluxAmount) # "}";
                case (#Err(_e)) Utils.handleMintError("Flux", _e);
            };

            _tokensResults := shardsResult # ", " # fluxResult;
        };
        case (#Err(_e)) {
            return (false, Utils.handleChestError(_e));
        };
    };

    return (true, _tokensResults);
};

// Rewards
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
  

// QRewards
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


};
