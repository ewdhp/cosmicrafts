module TypesAchievements {

      public type PlayerId = Principal;

      public type AchievementType = {
            #GamesWon;
            #GamesPlayed;
            #TimePlayed;
            #FriendsAdded;
            #LevelReached;
            #NFTsMinted;
            #FluxMinted;
            #ShardsMinted;
            #ChestsMinted;
            #DamageDealt;
            #DamageTaken;
            #EnergyUsed;
            #UnitsDeployed;
            #GamesWithFaction;
            #GamesWithCharacter;
            #GameModePlayed;
            #XPEarned;
            #Kills;
            #GamesCompleted;
            #AchievementsUnlocked;
            #RewardsClaimed;
            #ChestsOpened;
            #DailyMissionsCompleted;
            #WeeklyMissionsCompleted;
            #UserMissionsCompleted;
      };

  public type AchievementRewardsType = {
    #Shards;
    #Item;
    #Title;
    #Avatar;
    #Chest;
    #Flux;
    #NFT;
    #CosmicPower;
  };

  public type AchievementReward = {
    rewardType: AchievementRewardsType;
    amount: Nat;
    items: [Text];
    title: Text;
  };

  // Achievement Category
  public type AchievementCategory = {
    #Combat;
    #Exploration;
    #Social;
    #Progression;
    #Milestone;
  };

  // Achievement Tier
  public type AchievementTier = {
    #Bronze;
    #Silver;
    #Gold;
    #Platinum;
    #Diamond;
    #Master;
    #Legend;
  };

  // Achievement Structure
  public type Achievement = {
    id: Nat;
    name: Text;
    achievementType: AchievementType;
    category: AchievementCategory;
    tier: AchievementTier;
    reward: AchievementReward;
    progress: Nat;
    completed: Bool;
  };

  // Achievement Progress
  public type AchievementProgress = {
    achievementId: Nat;
    playerId: PlayerId;
    progress: Nat;
    completed: Bool;
  };
}