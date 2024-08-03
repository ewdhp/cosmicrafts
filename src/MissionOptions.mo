import Types "Types";

module MissionOptions {

    // Constant of Concurrent Missions
    public let hourlyMissions: [Types.MissionTemplate] = [
        {
            name = "Complete 1 Game";
            missionType = #GamesCompleted;
            rewardType = #Shards;
            minReward = 18;
            maxReward = 36;
            total = 1;
            hoursActive = 1;
        },
        {
            name = "Win 1 Game";
            missionType = #GamesWon;
            rewardType = #Chest;
            minReward = 2;
            maxReward = 4;
            total = 1;
            hoursActive = 1;
        },
        {
            name = "Deal 1000 Damage";
            missionType = #DamageDealt;
            rewardType = #Shards;
            minReward = 20;
            maxReward = 42;
            total = 1000;
            hoursActive = 1;
        },
        {
            name = "Take 500 Damage";
            missionType = #DamageTaken;
            rewardType = #Chest;
            minReward = 1;
            maxReward = 3;
            total = 500;
            hoursActive = 1;
        },
        {
            name = "Use 35 Energy";
            missionType = #EnergyUsed;
            rewardType = #Shards;
            minReward = 22;
            maxReward = 38;
            total = 35;
            hoursActive = 1;
        },
        {
            name = "Deploy 20 NFTs";
            missionType = #UnitsDeployed;
            rewardType = #Shards;
            minReward = 22;
            maxReward = 42;
            total = 20;
            hoursActive = 1;
        },
        {
            name = "Earn 1000 XP";
            missionType = #XPEarned;
            rewardType = #Chest;
            minReward = 2;
            maxReward = 3;
            total = 1000;
            hoursActive = 1;
        },
        {
            name = "Destroy 15 enemies";
            missionType = #Kills;
            rewardType = #Chest;
            minReward = 2;
            maxReward = 4;
            total = 15;
            hoursActive = 1;
        }
    ];

    public let dailyMissions: [Types.MissionTemplate] = [
        {
            name = "Complete 5 Games";
            missionType = #GamesCompleted;
            rewardType = #Shards;
            minReward = 128;
            maxReward = 256;
            total = 5;
            hoursActive = 24;
        },
        {
            name = "Win 3 Games";
            missionType = #GamesWon;
            rewardType = #Chest;
            minReward = 4;
            maxReward = 6;
            total = 3;
            hoursActive = 24;
        },
        {
            name = "Deal 10000 Damage";
            missionType = #DamageDealt;
            rewardType = #Shards;
            minReward = 128;
            maxReward = 256;
            total = 10000;
            hoursActive = 24;
        },
        {
            name = "Take 9000 Damage";
            missionType = #DamageTaken;
            rewardType = #Chest;
            minReward = 4;
            maxReward = 6;
            total = 9000;
            hoursActive = 24;
        },
        {
            name = "Use 300 Energy";
            missionType = #EnergyUsed;
            rewardType = #Shards;
            minReward = 128;
            maxReward = 360;
            total = 300;
            hoursActive = 24;
        },
        {
            name = "Deploy 100 NFTs";
            missionType = #UnitsDeployed;
            rewardType = #Shards;
            minReward = 128;
            maxReward = 300;
            total = 100;
            hoursActive = 24;
        },
        {
            name = "Earn 50000 XP";
            missionType = #XPEarned;
            rewardType = #Chest;
            minReward = 3;
            maxReward = 4;
            total = 50000;
            hoursActive = 24;
        },
        {
            name = "Destroy 50 Enemies";
            missionType = #Kills;
            rewardType = #Chest;
            minReward = 3;
            maxReward = 4;
            total = 50;
            hoursActive = 24;
        }
    ];

    public let weeklyMissions: [Types.MissionTemplate] = [
        {
            name = "Complete 20 Games";
            missionType = #GamesCompleted;
            rewardType = #Shards;
            minReward = 768;  // Adjusted to fit the 20% more/less range
            maxReward = 1728;  // Adjusted to fit the 20% more/less range
            total = 25;
            hoursActive = 168;  // 7 days
        },
        {
            name = "Win 10 Games";
            missionType = #GamesWon;
            rewardType = #Chest;
            minReward = 7;  // Chest rewards
            maxReward = 8;  // Chest rewards
            total = 10;
            hoursActive = 168;  // 7 days
        },
        {
            name = "Deal 50000 Damage";
            missionType = #DamageDealt;
            rewardType = #Shards;
            minReward = 800;  // Adjusted to fit the 20% more/less range
            maxReward = 2200;  // Adjusted to fit the 20% more/less range
            total = 50000;
            hoursActive = 168;  // 7 days
        },
        {
            name = "Take 25000 Damage";
            missionType = #DamageTaken;
            rewardType = #Chest;
            minReward = 6;  // Chest rewards
            maxReward = 8;  // Chest rewards
            total = 25000;
            hoursActive = 168;  // 7 days
        },
        {
            name = "Use 1000 Energy";
            missionType = #EnergyUsed;
            rewardType = #Shards;
            minReward = 768;  // Adjusted to fit the 20% more/less range
            maxReward = 1728;  // Adjusted to fit the 20% more/less range
            total = 1000;
            hoursActive = 168;  // 7 days
        },
        {
            name = "Deploy 250 NFTs";
            missionType = #UnitsDeployed;
            rewardType = #Shards;
            minReward = 900;  // Adjusted to fit the 20% more/less range
            maxReward = 2400;  // Adjusted to fit the 20% more/less range
            total = 250;
            hoursActive = 168;  // 7 days
        },
        {
            name = "Earn 200000 XP";
            missionType = #XPEarned;
            rewardType = #Chest;
            minReward = 6;  // Chest rewards
            maxReward = 8;  // Chest rewards
            total = 200000;
            hoursActive = 168;  // 7 days
        },
        {
            name = "Destroy 200 Enemies";
            missionType = #Kills;
            rewardType = #Chest;
            minReward = 6;  // Chest rewards
            maxReward = 8;  // Chest rewards
            total = 200;
            hoursActive = 168;  // 7 days
        }
    ];


    public let dailyFreeReward: [Types.MissionTemplate] = [
        {
        name = "Daily Free Chest";
        missionType = #GamesCompleted; // Not tied to gameplay
        rewardType = #Chest;
        minReward = 1;
        maxReward = 2;
        total = 0; // No gameplay required
        hoursActive = 4;
        },
        {
        name = "Daily Free Shards";
        missionType = #GamesCompleted; // Not tied to gameplay
        rewardType = #Chest;
        minReward = 1;
        maxReward = 2;
        total = 0; // No gameplay required
        hoursActive = 4;
        },
        {
        name = "Daily Free Flux";
        missionType = #GamesCompleted; // Not tied to gameplay
        rewardType = #Chest;
        minReward = 1;
        maxReward = 3;
        total = 0; // No gameplay required
        hoursActive = 4;
        }
    ];
}
