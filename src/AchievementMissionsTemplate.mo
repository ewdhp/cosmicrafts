import TypesAchievements "TypesAchievements";

module AchievementMissionsTemplate {


    public let achievements: [TypesAchievements.Achievement] = [
        {
            id = 1;
            name = "Win 1 Game";
            achievementType = #GamesWon;
            category = #Combat;
            tier = #Bronze;
            reward = {
                rewardType = #Flux;
                amount = 100;
                items = [];
                title = "";
            };
            progress = 1;
            completed = false;
        },
        {
            id = 2;
            name = "Win 10 Games";
            achievementType = #GamesWon;
            category = #Combat;
            tier = #Silver;
            reward = {
                rewardType = #Flux;
                amount = 1000;
                items = [];
                title = "";
            };
            progress = 10;
            completed = false;
        },
        {
            id = 3;
            name = "Add 5 Friends";
            achievementType = #FriendsAdded;
            category = #Social;
            tier = #Bronze;
            reward = {
                rewardType = #Title;
                amount = 0;
                items = [];
                title = "Friendly Player";
            };
            progress = 5;
            completed = false;
        },
        // Add more achievements as needed
    ];

    // Function to get a specific achievement by ID
    public func getAchievementById(id: Nat): ?TypesAchievements.Achievement {
        for (achievement in achievements.vals()) {
            if (achievement.id == id) {
                return ?achievement;
            }
        };
        return null;
    };

    // Function to get all achievements
    public func getAllAchievements(): [TypesAchievements.Achievement] {
        return achievements;
    };
}
