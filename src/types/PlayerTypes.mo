import Time "mo:base/Time";
module {
  public type PlayerId = Principal;
  public type PlayerName = Text;
  public type Level = Nat;
  public type GameID = Principal;
  public type Players = Principal;

  public type PlayerPreferences = {
    language : Nat;
    playerChar : Text;
  };

  public type Player = {
    id : PlayerId;
    name : PlayerName;
    level : Level;
    elo : Float;
  };

  //migration from comicrafts canister
  public type UserID = Principal;
  public type Username = Text;
  public type AvatarID = Nat;
  public type Description = Text;
  public type RegistrationDate = Time.Time;
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
  public type UserDetails = { user : UserRecord; friends : [FriendDetails] };

};
