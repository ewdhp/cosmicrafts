import Types "Types";

module MissionOptions {
  public let hourlyMissions: [Types.MissionTemplate] = [
    {
      name = "Win 1 Game";
      missionType = #GamesWon;
      rewardType = #Chest;
      minReward = 1;
      maxReward = 2;
      total = 1.0;
      hoursActive = 1;
    },
    {
      name = "Deal 5000 Damage";
      missionType = #DamageDealt;
      rewardType = #Chest;
      minReward = 1;
      maxReward = 2;
      total = 5000.0;
      hoursActive = 1;
    },
    {
      name = "Deploy 20 Units";
      missionType = #UnitsDeployed;
      rewardType = #Chest;
      minReward = 1;
      maxReward = 2;
      total = 20.0;
      hoursActive = 1;
    },
    {
      name = "Spend 3000 Energy";
      missionType = #EnergyUsed;
      rewardType = #Chest;
      minReward = 1;
      maxReward = 2;
      total = 3000.0;
      hoursActive = 1;
    }
  ];

  public let dailyMissions: [Types.MissionTemplate] = [
    {
      name = "Win 10 Games";
      missionType = #GamesWon;
      rewardType = #Chest;
      minReward = 3;
      maxReward = 4;
      total = 10.0;
      hoursActive = 24;
    },
    {
      name = "Deal 50000 Damage";
      missionType = #DamageDealt;
      rewardType = #Chest;
      minReward = 3;
      maxReward = 4;
      total = 50000.0;
      hoursActive = 24;
    },
    {
      name = "Deploy 100 Units";
      missionType = #UnitsDeployed;
      rewardType = #Chest;
      minReward = 3;
      maxReward = 4;
      total = 100.0;
      hoursActive = 24;
    },
    {
      name = "Spend 15000 Energy";
      missionType = #EnergyUsed;
      rewardType = #Chest;
      minReward = 3;
      maxReward = 4;
      total = 15000.0;
      hoursActive = 24;
    }
  ];

  public let weeklyMissions: [Types.MissionTemplate] = [
    {
      name = "Win 50 Games";
      missionType = #GamesWon;
      rewardType = #Chest;
      minReward = 5;
      maxReward = 6;
      total = 50.0;
      hoursActive = 168; // 7 days * 24 hours
    },
    {
      name = "Deal 250000 Damage";
      missionType = #DamageDealt;
      rewardType = #Chest;
      minReward = 5;
      maxReward = 6;
      total = 250000.0;
      hoursActive = 168; // 7 days * 24 hours
    },
    {
      name = "Deploy 500 Units";
      missionType = #UnitsDeployed;
      rewardType = #Chest;
      minReward = 5;
      maxReward = 6;
      total = 500.0;
      hoursActive = 168; // 7 days * 24 hours
    },
    {
      name = "Spend 75000 Energy";
      missionType = #EnergyUsed;
      rewardType = #Chest;
      minReward = 5;
      maxReward = 6;
      total = 75000.0;
      hoursActive = 168; // 7 days * 24 hours
    }
  ];

  public let dailyFreeReward: Types.MissionTemplate = {
    name = "Daily Free Reward";
    missionType = #GamesCompleted; // Not tied to gameplay
    rewardType = #Chest;
    minReward = 1;
    maxReward = 1;
    total = 0.0; // No gameplay required
    hoursActive = 24;
  };
}
