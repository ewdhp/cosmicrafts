import Types "Types";

module MissionOptions {

    // Constants for mission options and reward pools
    public let missionOptions: [Types.MissionOption] = [
        { MissionType = #GamesCompleted; minAmount = 1; maxAmount = 5; rarity = 1 },
        { MissionType = #GamesWon; minAmount = 6; maxAmount = 10; rarity = 2 },
        { MissionType = #LevelReached; minAmount = 50; maxAmount = 100; rarity = 0 }
    ];

    public let rewardPools: [Types.RewardPool] = [
        { chestRarity = (2, 2); flux = (50, 100); shards = (100, 200) }, // Hourly
        { chestRarity = (3, 4); flux = (200, 300); shards = (300, 400) }, // Daily
        { chestRarity = (5, 6); flux = (500, 1000); shards = (1000, 2000) } // Weekly
    ];

    // Constant of Concurrent Missions
    public let hourlyMissions: [Types.MissionTemplate] = [
        {
            name = "Win 1 Game";
            missionType = #GamesWon;
            rewardType = #Chest;
            minReward = 1;
            maxReward = 2;
            total = 1;
            hoursActive = 1;
        },
        {
            name = "Deal 5000 Damage";
            missionType = #DamageDealt;
            rewardType = #Chest;
            minReward = 1;
            maxReward = 2;
            total = 5000;
            hoursActive = 1;
        },
        {
            name = "Deploy 20 Units";
            missionType = #UnitsDeployed;
            rewardType = #Chest;
            minReward = 1;
            maxReward = 2;
            total = 20;
            hoursActive = 1;
        },
        {
            name = "Spend 3000 Energy";
            missionType = #EnergyUsed;
            rewardType = #Chest;
            minReward = 1;
            maxReward = 2;
            total = 3000;
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
            total = 10;
            hoursActive = 24;
        },
        {
            name = "Deal 50000 Damage";
            missionType = #DamageDealt;
            rewardType = #Chest;
            minReward = 3;
            maxReward = 4;
            total = 50000;
            hoursActive = 24;
        },
        {
            name = "Deploy 100 Units";
            missionType = #UnitsDeployed;
            rewardType = #Chest;
            minReward = 3;
            maxReward = 4;
            total = 100;
            hoursActive = 24;
        },
        {
            name = "Spend 15000 Energy";
            missionType = #EnergyUsed;
            rewardType = #Chest;
            minReward = 3;
            maxReward = 4;
            total = 15000;
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
            total = 50;
            hoursActive = 168; // 7 days * 24 hours
        },
        {
            name = "Deal 250000 Damage";
            missionType = #DamageDealt;
            rewardType = #Chest;
            minReward = 5;
            maxReward = 6;
            total = 250000;
            hoursActive = 168; // 7 days * 24 hours
        },
        {
            name = "Deploy 500 Units";
            missionType = #UnitsDeployed;
            rewardType = #Chest;
            minReward = 5;
            maxReward = 6;
            total = 500;
            hoursActive = 168; // 7 days * 24 hours
        },
        {
            name = "Spend 75000 Energy";
            missionType = #EnergyUsed;
            rewardType = #Chest;
            minReward = 5;
            maxReward = 6;
            total = 75000;
            hoursActive = 168; // 7 days * 24 hours
        }
    ];

    public let dailyFreeReward: [Types.MissionTemplate] = [
        {
        name = "Daily Free Chest";
        missionType = #GamesCompleted; // Not tied to gameplay
        rewardType = #Chest;
        minReward = 1;
        maxReward = 1;
        total = 0; // No gameplay required
        hoursActive = 24;
        },
        {
        name = "Daily Free Flux";
        missionType = #GamesCompleted; // Not tied to gameplay
        rewardType = #Shards;
        minReward = 10;
        maxReward = 20;
        total = 0; // No gameplay required
        hoursActive = 24;
        },
        {
        name = "Daily Free Reward";
        missionType = #GamesCompleted; // Not tied to gameplay
        rewardType = #Flux;
        minReward = 4;
        maxReward = 8;
        total = 0; // No gameplay required
        hoursActive = 24;
        }
    ];
}
