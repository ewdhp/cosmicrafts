module TypesAchievements {

    public type PlayerId = Principal;

    // Individual Achievement relates to a single mission, e.g., "Play 3 games."
    public type IndividualAchievement = {
        id: Nat;
        name: Text;
        achievementType: AchievementType;
        requiredProgress: Nat;
        progress: Nat;
        completed: Bool;
        reward: [AchievementReward]; // Allowing multiple rewards
        achievementId: Nat; // Link to the general achievement
    };

    // Achievement represents a type of achievement, e.g., "Games Played."
    public type Achievement = {
        id: Nat;
        name: Text;
        individualAchievements: [Nat]; // List of related individual achievements
        tier: AchievementTier;
        progress: Nat;
        requiredProgress: Nat; // Total progress required to complete this achievement
        categoryId: Nat; // Link to the category
        reward: [AchievementReward]; // Allowing multiple rewards
        completed: Bool; // Field added to track completion status
    };

    // Achievement Category represents a grouping of achievements, e.g., "Progression."
    public type AchievementCategory = {
        id: Nat;
        name: Text;
        achievements: [Nat]; // List of related achievements
        tier: AchievementTier;
        progress: Nat;
        requiredProgress: Nat; // Total progress required to complete this category
        reward: [AchievementReward]; // Allowing multiple rewards
        completed: Bool; // Field added to track completion status
    };

    // Achievement Type
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

    // Achievement Reward Types
    public type AchievementRewardsType = {
        #Shards;
        #Chest;
        #Flux;
        #CosmicPower;
    };

    // Achievement Reward
    public type AchievementReward = {
        rewardType: AchievementRewardsType;
        amount: Nat;
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

    // Achievement Progress
    public type AchievementProgress = {
        achievementId: Nat;
        playerId: PlayerId;
        progress: Nat;
        completed: Bool;
    };

    // Individual Achievement Progress for User
    public type IndividualAchievementProgress = {
        individualAchievement: IndividualAchievement;
        progress: Nat;
        completed: Bool;
    };
}
