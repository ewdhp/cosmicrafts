module {
  public type UserId = Principal;

  public type MatchmakingStatus = {
    #Searching;
    #Reserved;
    #Accepting;
    #Accepted;
    #InGame;
    #Ended;
  };

  public type SearchStatus = {
    #Assigned;
    #Available;
    #NotAvailable;
  };

  public type PlayerInfo = {
    id : UserId;
    matchAccepted : Bool;
    elo : Float;
    playerGameData : Text;
    lastPlayerActive : Nat64;
    // characterSelected : Nat;
    // deckSavedKeyIds   : [Text];
  };

  public type FullPlayerInfo = {
    id : UserId;
    matchAccepted : Bool;
    elo : Float;
    playerGameData : Text;
    playerName : Text;
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
};
