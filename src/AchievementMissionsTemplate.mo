import TypesAchievements "TypesAchievements";

module AchievementMissionsTemplate {


    public let achievements: [TypesAchievements.Achievement] = [
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
