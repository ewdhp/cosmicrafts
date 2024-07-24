//Types 
    import Float "mo:base/Float";
    import HashMap "mo:base/HashMap";
    import Int "mo:base/Int";
    import Iter "mo:base/Iter";
    import Nat "mo:base/Nat";
    import Nat64 "mo:base/Nat64";
    import Principal "mo:base/Principal";
    import Time "mo:base/Time";
    import Buffer "mo:base/Buffer";
    import Array "mo:base/Array";
    import Result "mo:base/Result";
    import Debug "mo:base/Debug";
    import Text "mo:base/Text";
    import Random "mo:base/Random";
    import Nat8 "mo:base/Nat8";
    import Timer "mo:base/Timer";
    import Blob "mo:base/Blob";
    import Bool "mo:base/Bool";

    import Types "Types";
    import Utils "Utils";
    import TypesICRC7 "/icrc7/types";
    import TypesICRC1 "/icrc1/Types";
    import Validator "Validator";
    import MissionOptions "MissionOptions";

shared actor class Cosmicrafts() {

  stable var _cosmicraftsPrincipal : Principal = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai");

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

  public type MissionType = Types.MissionType;
  public type RewardType = Types.RewardType;
  public type Mission = Types.Mission;
  public type MissionsUser = Types.MissionsUser;


  public type MissionProgress = Types.MissionProgress;
  public type MissionTemplate = Types.MissionTemplate;
  public type RewardPool = Types.RewardPool;
  public type MissionOption = Types.MissionOption;

  //Timer
  public type Duration = Timer.Duration;
  public type TimerId = Timer.TimerId;

  //ICRC
  public type TokenID = Types.TokenID;





// Admin Tools

    // Define the admin principal
    let ADMIN_PRINCIPAL = Principal.fromText("vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae");

    // Define an enum for the different functions
    public type AdminFunction = {
        #CreateMission : (Text, MissionType, RewardType, Nat, Nat, Nat64);
        #CreateMissionsPeriodically : ();
    };

    // Define a public admin function to call private functions
    public shared({ caller }) func adminManagement(funcToCall: AdminFunction) : async (Bool, Text) {
        if (caller == ADMIN_PRINCIPAL) {
            Debug.print("Admin function called by admin.");
            switch (funcToCall) {
                case (#CreateMission(name, missionType, rewardType, rewardAmount, total, hours_active)) {
                    let (success, message, id) = await createGeneralMission(name, missionType, rewardType, rewardAmount, total, hours_active);
                    return (success, message # " Mission ID: " # Nat.toText(id));
                };
                case (#CreateMissionsPeriodically()) {
                    await createMissionsPeriodically();
                    return (true, "Missions created.");
                };
            }
        } else {
            return (false, "Access denied: Only admin can call this function.");
        }
    };



// Missions

    let ONE_HOUR: Nat64 = 60 * 60 * 1_000_000_000;
    let ONE_DAY: Nat64 = 60 * 60 * 24 * 1_000_000_000;
    let ONE_WEEK: Nat64 = 60 * 60 * 24 * 7 * 1_000_000_000; // 60 secs * 60 minutes * 24 hours * 7


// New Concurrent Mission System
    var lastDailyMissionCreationTime: Nat64 = 0;
    var lastWeeklyMissionCreationTime: Nat64 = 0;

    stable var shuffledDailyIndices: [Nat] = [];
    stable var currentDailyIndex: Nat = 0;

    stable var shuffledHourlyIndices: [Nat] = [];
    stable var currentHourlyIndex: Nat = 0;

    stable var shuffledWeeklyIndices: [Nat] = [];
    stable var currentWeeklyIndex: Nat = 0;

    stable var shuffledDailyFreeRewardIndices: [Nat] = [];
    stable var currentDailyFreeRewardIndex: Nat = 0;


    func initializeShuffledHourlyMissions(): async () {
        let indices: [Nat] = Array.tabulate(MissionOptions.hourlyMissions.size(), func(i: Nat): Nat { i });
        shuffledHourlyIndices := await Utils.shuffleArray(indices);
        currentHourlyIndex := 0;
    };

    func initializeShuffledDailyMissions(): async () {
        let indices: [Nat] = Array.tabulate(MissionOptions.dailyMissions.size(), func(i: Nat): Nat { i });
        shuffledDailyIndices := await Utils.shuffleArray(indices);
        currentDailyIndex := 0;
    };

    func initializeShuffledWeeklyMissions(): async () {
        let indices: [Nat] = Array.tabulate(MissionOptions.weeklyMissions.size(), func(i: Nat): Nat { i });
        shuffledWeeklyIndices := await Utils.shuffleArray(indices);
        currentWeeklyIndex := 0;
    };

    func initializeShuffledDailyFreeRewardMissions(): async () {
        let indices: [Nat] = Array.tabulate(MissionOptions.dailyFreeReward.size(), func(i: Nat): Nat { i });
        shuffledDailyFreeRewardIndices := await Utils.shuffleArray(indices);
        currentDailyFreeRewardIndex := 0;
    };

    public func createDailyMissions(): async [(Bool, Text, Nat)] {
        var results: [(Bool, Text, Nat)] = [];

        // Check if the list needs to be shuffled
        if (shuffledDailyIndices.size() == 0 or currentDailyIndex >= shuffledDailyIndices.size()) {
            await initializeShuffledDailyMissions();
        };

        // Select the next mission from the shuffled list
        let index = shuffledDailyIndices[currentDailyIndex];
        let template = MissionOptions.dailyMissions[index];
        let result = await createSingleConcurrentMission(template);
        results := Array.append(results, [result]);

        // Move to the next index
        currentDailyIndex += 1;

        return results;
    };

    public func createWeeklyMissions(): async [(Bool, Text, Nat)] {
        var results: [(Bool, Text, Nat)] = [];

        // Check if the list needs to be shuffled
        if (shuffledWeeklyIndices.size() == 0 or currentWeeklyIndex >= shuffledWeeklyIndices.size()) {
            await initializeShuffledWeeklyMissions();
        };

        // Select the next mission from the shuffled list
        let index = shuffledWeeklyIndices[currentWeeklyIndex];
        let template = MissionOptions.weeklyMissions[index];
        let result = await createSingleConcurrentMission(template);
        results := Array.append(results, [result]);

        // Move to the next index
        currentWeeklyIndex += 1;

        return results;
    };

    public func createDailyFreeRewardMissions(): async [(Bool, Text, Nat)] {
        var results: [(Bool, Text, Nat)] = [];

        // Check if the list needs to be shuffled
        if (shuffledDailyFreeRewardIndices.size() == 0 or currentDailyFreeRewardIndex >= shuffledDailyFreeRewardIndices.size()) {
            await initializeShuffledDailyFreeRewardMissions();
        };

        // Select the next mission from the shuffled list
        let index = shuffledDailyFreeRewardIndices[currentDailyFreeRewardIndex];
        let template = MissionOptions.dailyFreeReward[index];
        let result = await createSingleConcurrentMission(template);
        results := Array.append(results, [result]);

        // Move to the next index
        currentDailyFreeRewardIndex += 1;

        return results;
    };

    func getRandomReward(minReward: Nat, maxReward: Nat): async Nat {
        let randomBytes = await Random.blob(); // Generating random bytes
        let byteArray = Blob.toArray(randomBytes);
        let randomByte = byteArray[0]; // Use the first byte for randomness
        let range = maxReward - minReward + 1;
        let randomValue = Nat8.toNat(randomByte) % range;
        return minReward + randomValue;
    };

    func createSingleConcurrentMission(template: Types.MissionTemplate): async (Bool, Text, Nat) {
        let rewardAmount = await getRandomReward(template.minReward, template.maxReward);
        return await createGeneralMission(
            template.name,
            template.missionType,
            template.rewardType,
            rewardAmount,
            template.total,
            template.hoursActive
        );
    };

    func createMissionsPeriodically(): async () {
        let now = Nat64.fromIntWrap(Time.now());
        Debug.print("[createMissionsPeriodically] Current time: " # Nat64.toText(now));

        // Create and assign daily missions
        if (now - lastDailyMissionCreationTime >= ONE_DAY) {
            let dailyResults = await createDailyMissions();
            await Utils.logMissionResults(dailyResults, "Daily");
            let dailyFreeResults = await createDailyFreeRewardMissions();
            await Utils.logMissionResults(dailyFreeResults, "Daily Free Reward");
            lastDailyMissionCreationTime := now;
        };

        // Create and assign weekly missions
        if (now - lastWeeklyMissionCreationTime >= ONE_WEEK) {
            let weeklyResults = await createWeeklyMissions();
            await Utils.logMissionResults(weeklyResults, "Weekly");
            lastWeeklyMissionCreationTime := now;
        };

        // Set the timer to call this function again after 1 hour
        let _ : Timer.TimerId = Timer.setTimer<system>(#seconds(60 * 60), func(): async () {
            await createMissionsPeriodically();
        });
    };

//----

// General Missions
    stable var generalMissionIDCounter: Nat = 1;
    stable var _generalUserProgress: [(Principal, [MissionsUser])] = [];
    stable var _missions: [(Nat, Mission)] = [];
    stable var _activeMissions: [(Nat, Mission)] = [];
    stable var _claimedRewards: [(Principal, [Nat])] = [];

    // HashMaps for General Missions
    var missions: HashMap.HashMap<Nat, Mission> = HashMap.fromIter(_missions.vals(), 0, Utils._natEqual, Utils._natHash);
    var activeMissions: HashMap.HashMap<Nat, Mission> = HashMap.fromIter(_activeMissions.vals(), 0, Utils._natEqual, Utils._natHash);
    var claimedRewards: HashMap.HashMap<Principal, [Nat]> = HashMap.fromIter(_claimedRewards.vals(), 0, Principal.equal, Principal.hash);
    var generalUserProgress: HashMap.HashMap<Principal, [MissionsUser]> = HashMap.fromIter(_generalUserProgress.vals(), 0, Principal.equal, Principal.hash);

    // Function to create a new general mission
    public func createGeneralMission(name: Text, missionType: MissionType, rewardType: RewardType, rewardAmount: Nat, total: Nat, hoursActive: Nat64): async (Bool, Text, Nat) {
        let id = generalMissionIDCounter;
        generalMissionIDCounter += 1;

        let now = Nat64.fromIntWrap(Time.now());
        let duration = ONE_HOUR * hoursActive;
        let endDate = now + duration;

        let newMission: Mission = {
            id = id;
            name = name;
            missionType = missionType;
            reward_type = rewardType;
            reward_amount = rewardAmount;
            start_date = now;
            end_date = endDate;
            total = total;
        };

        missions.put(id, newMission);
        activeMissions.put(id, newMission);
        Debug.print("[createGeneralMission] Mission created with ID: " # Nat.toText(id) # ", End Date: " # Nat64.toText(endDate) # ", Start Date: " # Nat64.toText(now));

        return (true, "Mission created successfully", id);
    };

    // Function to update progress for general missions
public func updateGeneralMissionProgress(user: Principal, missionsProgress: [MissionProgress]): async (Bool, Text) {
    Debug.print("[updateGeneralMissionProgress] Updating general mission progress for user: " # Principal.toText(user));
    Debug.print("[updateGeneralMissionProgress] Missions progress: " # debug_show(missionsProgress));

    var userMissions: [MissionsUser] = switch (generalUserProgress.get(user)) {
        case (null) { [] };
        case (?missions) { missions };
    };

    Debug.print("[updateGeneralMissionProgress] User's current missions: " # debug_show(userMissions));

    let now: Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    let updatedMissions = Buffer.Buffer<MissionsUser>(userMissions.size());

    for (mission in userMissions.vals()) {
        Debug.print("[updateGeneralMissionProgress] Processing mission: " # debug_show(mission));
        if (mission.finished) {
            updatedMissions.add(mission);
        } else {
            var updatedMission = mission;
            for (progress in missionsProgress.vals()) {
                if (mission.missionType == progress.missionType) {
                    let updatedProgress = mission.progress + progress.progress;
                    Debug.print("[updateGeneralMissionProgress] Updated progress for missionType " # debug_show(mission.missionType) # ": " # debug_show(updatedProgress));
                    if (updatedProgress >= mission.total) {
                        updatedMission := {
                            mission with
                            progress = updatedProgress;
                            finished = true;
                            finish_date = now;
                        };
                    } else {
                        updatedMission := {
                            mission with
                            progress = updatedProgress;
                        };
                    };
                };
            };
            updatedMissions.add(updatedMission);
        };
    };

    generalUserProgress.put(user, Buffer.toArray(updatedMissions));
    Debug.print("[updateGeneralMissionProgress] Updated user missions: " # debug_show(generalUserProgress.get(user)));
    return (true, "Progress added successfully to general missions");
};


    // Function to assign new general missions to a user
    public func assignGeneralMissions(user: Principal): async () {
        Debug.print("[assignGeneralMissions] Assigning new general missions to user: " # Principal.toText(user));

        var userMissions: [MissionsUser] = switch (generalUserProgress.get(user)) {
            case (null) { [] };
            case (?missions) { missions };
        };

        Debug.print("[assignGeneralMissions] User missions before update: " # debug_show(userMissions));

        var claimedRewardsForUser: [Nat] = switch (claimedRewards.get(user)) {
            case (null) { [] };
            case (?claimed) { claimed };
        };

        let now = Nat64.fromNat(Int.abs(Time.now()));
        let buffer = Buffer.Buffer<MissionsUser>(0);

        // Remove expired or claimed missions
        for (mission in userMissions.vals()) {
            if (mission.expiration >= now and not Utils.arrayContains<Nat>(claimedRewardsForUser, mission.id_mission, Utils._natEqual)) {
                buffer.add(mission);
            }
        };

        // Collect IDs of current missions to avoid duplication
        let currentMissionIds = Buffer.Buffer<Nat>(buffer.size());
        for (mission in buffer.vals()) {
            currentMissionIds.add(mission.id_mission);
        };

        // Add new active missions to the user
        for ((id, mission) in activeMissions.entries()) {
            if (not Utils.arrayContains<Nat>(Buffer.toArray(currentMissionIds), id, Utils._natEqual) and not Utils.arrayContains<Nat>(claimedRewardsForUser, id, Utils._natEqual)) {
                buffer.add({
                    id_mission = id;
                    reward_amount = mission.reward_amount;
                    start_date = mission.start_date;
                    progress = 0; // Initialize with 0 progress
                    finish_date = 0; // Initialize finish date to 0
                    expiration = mission.end_date;
                    missionType = mission.missionType;
                    finished = false;
                    reward_type = mission.reward_type;
                    total = mission.total;
                });
            }
        };

        generalUserProgress.put(user, Buffer.toArray(buffer));

        Debug.print("[assignGeneralMissions] User missions after update: " # debug_show(generalUserProgress.get(user)));
    };

    // Function to get general missions for a user
    public shared ({ caller }) func getGeneralMissions(): async [MissionsUser] {
        // Step 1: Assign new general missions to the user
        await assignGeneralMissions(caller);

        // Step 2: Search for active general missions assigned to the user
        let activeMissions: [MissionsUser] = await searchActiveGeneralMissions(caller);

        // Step 3: Get progress for each active general mission
        let missionsWithProgress = Buffer.Buffer<MissionsUser>(activeMissions.size());
        for (mission in activeMissions.vals()) {
            let missionProgress = await getGeneralMissionProgress(caller, mission.id_mission);
            switch (missionProgress) {
                case (null) {};
                case (?progress) {
                    missionsWithProgress.add(progress);
                };
            };
        };

        return Buffer.toArray(missionsWithProgress);
    };

    // Function to search for active general missions for a user
    public query func searchActiveGeneralMissions(user: Principal): async [MissionsUser] {
        let now: Nat64 = Nat64.fromNat(Int.abs(Time.now()));
        var userMissions: [MissionsUser] = switch (generalUserProgress.get(user)) {
            case (null) { [] };
            case (?missions) { missions };
        };

        var claimedRewardsForUser: [Nat] = switch (claimedRewards.get(user)) {
            case (null) { [] };
            case (?claimed) { claimed };
        };

        let activeMissions = Buffer.Buffer<MissionsUser>(0);
        for (mission in userMissions.vals()) {
            if (mission.expiration >= now and not Utils.arrayContains<Nat>(claimedRewardsForUser, mission.id_mission, Utils._natEqual)) {
                activeMissions.add(mission);
            }
        };

        return Buffer.toArray(activeMissions);
    };

    // Function to get the progress of a specific general mission for a user
    public query func getGeneralMissionProgress(user: Principal, missionID: Nat): async ?MissionsUser {
        let userMissions: [MissionsUser] = switch (generalUserProgress.get(user)) {
            case (null) return null;
            case (?missions) missions;
        };

        for (mission in userMissions.vals()) {
            if (mission.id_mission == missionID) {
                return ?mission;
            };
        };
        return null;
    };

    // Function to claim a reward for a general mission
    public shared(msg) func claimGeneralReward(idMission: Nat): async (Bool, Text) {
        let missionOpt = await getGeneralMissionProgress(msg.caller, idMission);
        switch (missionOpt) {
            case (null) {
                return (false, "Mission not assigned");
            };
            case (?mission) {
                let currentTime: Nat64 = Nat64.fromNat(Int.abs(Time.now()));

                // Check if the mission has expired
                if (currentTime > mission.expiration) {
                    return (false, "Mission has expired");
                };

                // Check if the mission reward has already been claimed
                let claimedRewardsForUser = switch (claimedRewards.get(msg.caller)) {
                    case (null) { [] };
                    case (?rewards) { rewards };
                };
                if (Array.find<Nat>(claimedRewardsForUser, func(r) { r == idMission }) != null) {
                    return (false, "Mission reward has already been claimed");
                };

                // Check if the mission is finished
                if (not mission.finished) {
                    return (false, "Mission not finished");
                };

                // Check if the finish date is valid (should be before or equal to expiration date)
                if (mission.finish_date > mission.expiration) {
                    return (false, "Mission finish date is after the expiration date");
                };

                // If all checks pass, mint the rewards
                let (success, message) = await mintGeneralRewards(mission, msg.caller);
                if (success) {
                    // Remove claimed reward from userProgress and add it to claimedRewards
                    var userMissions: [MissionsUser] = switch (generalUserProgress.get(msg.caller)) {
                        case (null) { [] };
                        case (?missions) { missions };
                    };
                    let updatedMissions = Buffer.Buffer<MissionsUser>(userMissions.size());
                    for (r in userMissions.vals()) {
                        if (r.id_mission != idMission) {
                            updatedMissions.add(r);
                        }
                    };
                    generalUserProgress.put(msg.caller, Buffer.toArray(updatedMissions));

                    // Add claimed reward to claimedRewards
                    claimedRewards.put(msg.caller, Array.append(claimedRewardsForUser, [idMission]));
                };
                return (success, message);
            };
        };
    };

    func mintGeneralRewards(mission: MissionsUser, caller: Principal): async (Bool, Text) {
        var claimHistory = switch (claimedRewards.get(caller)) {
            case (null) { [] };
            case (?history) { history };
        };

        if (Utils.arrayContains(claimHistory, mission.id_mission, Utils._natEqual)) {
            return (false, "Mission already claimed");
        };

        switch (mission.reward_type) {
            case (#Chest) {
                let uuid = await Utils.generateUUID64();
                let mintArgs: TypesICRC7.MintArgs = {
                    to = { owner = caller; subaccount = null };
                    token_id = uuid;
                    metadata = Utils.getChestMetadata(mission.reward_amount);
                };
                let mintResult = await chests.mint(mintArgs);
                switch (mintResult) {
                    case (#Ok(_transactionID)) {
                        claimHistory := Array.append(claimHistory, [mission.id_mission]);
                        claimedRewards.put(caller, claimHistory);
                        return (true, "Chest minted and reward claimed. UUID: " # Nat.toText(uuid) # ", Rarity: " # Nat.toText(mission.reward_amount));
                    };
                    case (#Err(_error)) {
                        return (false, "Minting chest failed");
                    };
                };
            };
            case (#Flux) {
                let mintArgs: TypesICRC1.Mint = {
                    to = { owner = caller; subaccount = null };
                    amount = mission.reward_amount;
                    memo = null;
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };
                let mintResult = await flux.mint(mintArgs);
                switch (mintResult) {
                    case (#Ok(_transactionID)) {
                        claimHistory := Array.append(claimHistory, [mission.id_mission]);
                        claimedRewards.put(caller, claimHistory);
                        return (true, "Flux minted and reward claimed. Quantity: " # Nat.toText(mission.reward_amount));
                    };
                    case (#Err(_error)) {
                        return (false, "Minting flux failed");
                    };
                };
            };
            case (#Shards) {
                let mintArgs: TypesICRC1.Mint = {
                    to = { owner = caller; subaccount = null };
                    amount = mission.reward_amount;
                    memo = null;
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };
                let mintResult = await shards.mint(mintArgs);
                switch (mintResult) {
                    case (#Ok(_transactionID)) {
                        claimHistory := Array.append(claimHistory, [mission.id_mission]);
                        claimedRewards.put(caller, claimHistory);
                        return (true, "Shards minted and reward claimed. Quantity: " # Nat.toText(mission.reward_amount));
                    };
                    case (#Err(_error)) {
                        return (false, "Minting shards failed");
                    };
                };
            };
        };
    };


//--

// User-Specific Missions
    stable var _userMissionProgress: [(Principal, [MissionsUser])] = [];
    stable var _userMissions: [(Principal, [Mission])] = [];
    stable var _userMissionCounters: [(Principal, Nat)] = [];
    stable var _userClaimedRewards: [(Principal, [Nat])] = [];

    // HashMaps for User-Specific Missions
    var userMissionProgress: HashMap.HashMap<Principal, [MissionsUser]> = HashMap.fromIter(_userMissionProgress.vals(), 0, Principal.equal, Principal.hash);
    var userMissions: HashMap.HashMap<Principal, [Mission]> = HashMap.fromIter(_userMissions.vals(), 0, Principal.equal, Principal.hash);
    var userMissionCounters: HashMap.HashMap<Principal, Nat> = HashMap.fromIter(_userMissionCounters.vals(), 0, Principal.equal, Principal.hash);
    var userClaimedRewards: HashMap.HashMap<Principal, [Nat]> = HashMap.fromIter(_userClaimedRewards.vals(), 0, Principal.equal, Principal.hash);

    // Function to create a new user-specific mission
    public func createUserMission(user: PlayerId): async (Bool, Text, Nat) {
        Debug.print("Starting createUserMission");

        var userMissionsList: [Mission] = switch (userMissions.get(user)) {
            case (null) { [] };
            case (?missions) { missions };
        };

        var userSpecificProgressList: [MissionsUser] = switch (userMissionProgress.get(user)) {
            case (null) { [] };
            case (?progress) { progress };
        };

        // Debug logging
        Debug.print("User Missions: " # debug_show(userMissionsList));
        Debug.print("User Progress List: " # debug_show(userSpecificProgressList));

        // Check the last mission for the user
        if (userSpecificProgressList.size() > 0) {
            let lastMissionProgress = userSpecificProgressList[userSpecificProgressList.size() - 1];
            let currentTime = Nat64.fromNat(Int.abs(Time.now()));

            // Debug logging
            Debug.print("Last Mission Progress: " # debug_show(lastMissionProgress));
            Debug.print("Current Time: " # debug_show(currentTime));

            // Expiration check logic
            if (not lastMissionProgress.finished and currentTime <= lastMissionProgress.expiration) {
                Debug.print("Current mission is still active: " # debug_show(lastMissionProgress));
                return (false, "Current mission is still active", lastMissionProgress.id_mission);
            } else {
                Debug.print("Current mission is not active or is finished");
            }
        };

        // Check if the list needs to be shuffled
        if (shuffledHourlyIndices.size() == 0 or currentHourlyIndex >= shuffledHourlyIndices.size()) {
            await initializeShuffledHourlyMissions();
        };

        // Select the next mission from the shuffled list
        let index = shuffledHourlyIndices[currentHourlyIndex];
        let template = MissionOptions.hourlyMissions[index];

        // Generate a random reward amount using the provided helper function
        let rewardAmount = await getRandomReward(template.minReward, template.maxReward);

        // Move to the next index
        currentHourlyIndex += 1;

        // Retrieve the user's mission ID counter
        let missionIDCounter = switch (userMissionCounters.get(user)) {
            case (null) { 0 };
            case (?counter) { counter };
        };

        let now = Nat64.fromNat(Int.abs(Time.now()));
        let newMission: Mission = {
            id = missionIDCounter;
            name = template.name;
            missionType = template.missionType;
            reward_type = template.rewardType;
            reward_amount = rewardAmount;
            start_date = now;
            end_date = now + (template.hoursActive * ONE_HOUR);
            total = template.total;
        };

        // Debug logging
        Debug.print("New Mission: " # debug_show(newMission));

        userMissionCounters.put(user, missionIDCounter + 1);

        userMissionsList := Array.append(userMissionsList, [newMission]);
        userMissions.put(user, userMissionsList);

        // Assign the new mission to the user
        await assignUserMissions(user);

        Debug.print("Mission created and assigned successfully");

        return (true, "User-specific mission created and assigned.", newMission.id);
    };

    // Function to update progress for user-specific missions
public shared func updateUserMissions(user: Principal, playerStats: {
    secRemaining: Nat;
    energyGenerated: Nat;
    damageDealt: Nat;
    damageTaken: Nat;
    energyUsed: Nat;
    deploys: Nat;
    faction: Nat;
    gameMode: Nat;
    xpEarned: Nat;
    kills: Nat;
    wonGame: Bool;
}): async (Bool, Text) {

    Debug.print("[updateUserMissions] Updating user-specific mission progress for user: " # Principal.toText(user));
    Debug.print("[updateUserMissions] Player stats: " # debug_show(playerStats));

    var userSpecificProgressList = switch (userMissionProgress.get(user)) {
        case (null) { [] };
        case (?progress) { progress };
    };

    Debug.print("[updateUserMissions] User's current missions: " # debug_show(userSpecificProgressList));

    let now: Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    let updatedMissions = Buffer.Buffer<MissionsUser>(userSpecificProgressList.size());

    for (mission in userSpecificProgressList.vals()) {
        Debug.print("[updateUserMissions] Processing mission: " # debug_show(mission));
        if (mission.finished) {
            updatedMissions.add(mission);
        } else {
            var updatedMission = mission;

            switch (mission.missionType) {
                case (#GamesCompleted) {
                    updatedMission := { mission with progress = mission.progress + 1 };
                };
                case (#GamesWon) {
                    if (playerStats.secRemaining > 0) {
                        updatedMission := { mission with progress = mission.progress + 1 };
                    };
                };
                case (#DamageDealt) {
                    updatedMission := { mission with progress = mission.progress + playerStats.damageDealt };
                };
                case (#DamageTaken) {
                    updatedMission := { mission with progress = mission.progress + playerStats.damageTaken };
                };
                case (#EnergyUsed) {
                    updatedMission := { mission with progress = mission.progress + playerStats.energyUsed };
                };
                case (#UnitsDeployed) {
                    updatedMission := { mission with progress = mission.progress + playerStats.deploys };
                };
                case (#FactionPlayed) {
                    updatedMission := { mission with progress = mission.progress + playerStats.faction };
                };
                case (#GameModePlayed) {
                    updatedMission := { mission with progress = mission.progress + playerStats.gameMode };
                };
                case (#XPEarned) {
                    updatedMission := { mission with progress = mission.progress + playerStats.xpEarned };
                };
                case (#Kills) {
                    updatedMission := { mission with progress = mission.progress + playerStats.kills };
                };
            };

            Debug.print("[updateUserMissions] Updated mission progress: " # debug_show(updatedMission.progress));

            if (updatedMission.progress >= updatedMission.total) {
                updatedMission := {
                    updatedMission with
                    progress = updatedMission.total;
                    finished = true;
                    finish_date = now;
                };
            };

            updatedMissions.add(updatedMission);
        };
    };

    userMissionProgress.put(user, Buffer.toArray(updatedMissions));
    Debug.print("[updateUserMissions] Updated user missions: " # debug_show(userMissionProgress.get(user)));
    return (true, "Progress updated successfully in user-specific missions");
};



    // Function to assign new user-specific missions to a user
    func assignUserMissions(user: PlayerId): async () {
        Debug.print("[assignUserMissions] Assigning new user-specific missions to user: " # Principal.toText(user));

        var userSpecificProgressList: [MissionsUser] = switch (userMissionProgress.get(user)) {
            case (null) { [] };
            case (?missions) { missions };
        };

        Debug.print("[assignUserMissions] User missions before update: " # debug_show(userSpecificProgressList));

        var claimedRewardsForUser: [Nat] = switch (userClaimedRewards.get(user)) {
            case (null) { [] };
            case (?claimed) { claimed };
        };

        let now = Nat64.fromNat(Int.abs(Time.now()));
        let buffer = Buffer.Buffer<MissionsUser>(0);

        // Remove expired or claimed missions
        for (mission in userSpecificProgressList.vals()) {
            if (mission.expiration >= now and not Utils.arrayContains<Nat>(claimedRewardsForUser, mission.id_mission, Utils._natEqual)) {
                buffer.add(mission);
            }
        };

        // Collect IDs of current missions to avoid duplication
        let currentMissionIds = Buffer.Buffer<Nat>(buffer.size());
        for (mission in buffer.vals()) {
            currentMissionIds.add(mission.id_mission);
        };

        // Add new active missions to the user
        for ((_, missions) in userMissions.entries()) {
            for (mission in missions.vals()) {
                if (not Utils.arrayContains<Nat>(Buffer.toArray(currentMissionIds), mission.id, Utils._natEqual) and not Utils.arrayContains<Nat>(claimedRewardsForUser, mission.id, Utils._natEqual)) {
                    buffer.add({
                        id_mission = mission.id;
                        reward_amount = mission.reward_amount;
                        start_date = mission.start_date;
                        progress = 0; // Initialize with 0 progress
                        finish_date = 0; // Initialize finish date to 0
                        expiration = mission.end_date;
                        missionType = mission.missionType;
                        finished = false;
                        reward_type = mission.reward_type;
                        total = mission.total;
                    });
                }
            }
        };

        userMissionProgress.put(user, Buffer.toArray(buffer));

        Debug.print("[assignUserMissions] User missions after update: " # debug_show(userMissionProgress.get(user)));
    };

    // Function to get user-specific missions for a user
    public shared ({ caller }) func getUserMissions(): async [MissionsUser] {
        // Step 1: Assign new user-specific missions to the user
        await assignUserMissions(caller);

        // Step 2: Search for active user-specific missions assigned to the user
        let activeMissions: [MissionsUser] = await searchActiveUserMissions(caller);

        // Step 3: Get progress for each active user-specific mission
        let missionsWithProgress = Buffer.Buffer<MissionsUser>(activeMissions.size());
        for (mission in activeMissions.vals()) {
            let missionProgress = await getUserMissionProgress(caller, mission.id_mission);
            switch (missionProgress) {
                case (null) {};
                case (?progress) {
                    missionsWithProgress.add(progress);
                };
            };
        };

        return Buffer.toArray(missionsWithProgress);
    };

    // Function to search for active user-specific missions
    public query func searchActiveUserMissions(user: PlayerId): async [MissionsUser] {
        let now: Nat64 = Nat64.fromNat(Int.abs(Time.now()));
        var userMissions = switch (userMissionProgress.get(user)) {
            case (null) { [] };
            case (?missions) { missions };
        };

        var claimedRewardsForUser = switch (userClaimedRewards.get(user)) {
            case (null) { [] };
            case (?claimed) { claimed };
        };

        let activeMissions = Buffer.Buffer<MissionsUser>(0);
        for (mission in userMissions.vals()) {
            if (mission.expiration >= now and not Utils.arrayContains<Nat>(claimedRewardsForUser, mission.id_mission, Utils._natEqual)) {
                activeMissions.add(mission);
            }
        };

        return Buffer.toArray(activeMissions);
    };

    // Function to get the progress of a user-specific mission
    public query func getUserMissionProgress(user: PlayerId, missionID: Nat): async ?MissionsUser {
        let userMissions = switch (userMissionProgress.get(user)) {
            case (null) return null;
            case (?missions) missions;
        };

        for (mission in userMissions.vals()) {
            if (mission.id_mission == missionID) {
                return ?mission;
            };
        };
        return null;
    };

    // Function to claim reward for a user-specific mission
    public shared(msg) func claimUserReward(idMission: Nat): async (Bool, Text) {
        let missionOpt = await getUserMissionProgress(msg.caller, idMission);
        switch (missionOpt) {
            case (null) {
                return (false, "Mission not assigned");
            };
            case (?mission) {
                let currentTime: Nat64 = Nat64.fromNat(Int.abs(Time.now()));

                // Check if the mission has expired
                if (currentTime > mission.expiration) {
                    return (false, "Mission has expired");
                };

                // Check if the mission reward has already been claimed
                let claimedRewardsForUser = switch (userClaimedRewards.get(msg.caller)) {
                    case (null) { [] };
                    case (?rewards) { rewards };
                };
                if (Array.find<Nat>(claimedRewardsForUser, func(r) { r == idMission }) != null) {
                    return (false, "Mission reward has already been claimed");
                };

                // Check if the mission is finished
                if (not mission.finished) {
                    return (false, "Mission not finished");
                };

                // Check if the finish date is valid (should be before or equal to expiration date)
                if (mission.finish_date > mission.expiration) {
                    return (false, "Mission finish date is after the expiration date");
                };

                // If all checks pass, mint the rewards
                let (success, message) = await mintUserRewards(mission, msg.caller);
                if (success) {
                    // Remove claimed reward from userProgress and add it to claimedRewards
                    var userMissions = switch (userMissionProgress.get(msg.caller)) {
                        case (null) { [] };
                        case (?missions) { missions };
                    };
                    let updatedMissions = Buffer.Buffer<MissionsUser>(userMissions.size());
                    for (r in userMissions.vals()) {
                        if (r.id_mission != idMission) {
                            updatedMissions.add(r);
                        }
                    };
                    userMissionProgress.put(msg.caller, Buffer.toArray(updatedMissions));

                    // Add claimed reward to userClaimedRewards
                    userClaimedRewards.put(msg.caller, Array.append(claimedRewardsForUser, [idMission]));
                };
                return (success, message);
            };
        };
    };

    func mintUserRewards(mission: MissionsUser, caller: Principal): async (Bool, Text) {
        var claimHistory = switch (userClaimedRewards.get(caller)) {
            case (null) { [] };
            case (?history) { history };
        };

        if (Utils.arrayContains(claimHistory, mission.id_mission, Utils._natEqual)) {
            return (false, "Mission already claimed");
        };

        switch (mission.reward_type) {
            case (#Chest) {
                let uuid = await Utils.generateUUID64();
                let mintArgs: TypesICRC7.MintArgs = {
                    to = { owner = caller; subaccount = null };
                    token_id = uuid;
                    metadata = Utils.getChestMetadata(mission.reward_amount);
                };
                let mintResult = await chests.mint(mintArgs);
                switch (mintResult) {
                    case (#Ok(_transactionID)) {
                        claimHistory := Array.append(claimHistory, [mission.id_mission]);
                        userClaimedRewards.put(caller, claimHistory);
                        return (true, "Chest minted and reward claimed. UUID: " # Nat.toText(uuid) # ", Rarity: " # Nat.toText(mission.reward_amount));
                    };
                    case (#Err(_error)) {
                        return (false, "Minting chest failed");
                    };
                };
            };
            case (#Flux) {
                let mintArgs: TypesICRC1.Mint = {
                    to = { owner = caller; subaccount = null };
                    amount = mission.reward_amount;
                    memo = null;
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };
                let mintResult = await flux.mint(mintArgs);
                switch (mintResult) {
                    case (#Ok(_transactionID)) {
                        claimHistory := Array.append(claimHistory, [mission.id_mission]);
                        userClaimedRewards.put(caller, claimHistory);
                        return (true, "Flux minted and reward claimed. Quantity: " # Nat.toText(mission.reward_amount));
                    };
                    case (#Err(_error)) {
                        return (false, "Minting flux failed");
                    };
                };
            };
            case (#Shards) {
                let mintArgs: TypesICRC1.Mint = {
                    to = { owner = caller; subaccount = null };
                    amount = mission.reward_amount;
                    memo = null;
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };
                let mintResult = await shards.mint(mintArgs);
                switch (mintResult) {
                    case (#Ok(_transactionID)) {
                        claimHistory := Array.append(claimHistory, [mission.id_mission]);
                        userClaimedRewards.put(caller, claimHistory);
                        return (true, "Shards minted and reward claimed. Quantity: " # Nat.toText(mission.reward_amount));
                    };
                    case (#Err(_error)) {
                        return (false, "Minting shards failed");
                    };
                };
            };
        };
    };


// Progress Manager

public shared func updateProgressManager(user: Principal, playerStats: {
    secRemaining: Nat;
    energyGenerated: Nat;
    damageDealt: Nat;
    damageTaken: Nat;
    energyUsed: Nat;
    deploys: Nat;
    faction: Nat;
    gameMode: Nat;
    xpEarned: Nat;
    kills: Nat;
    wonGame: Bool;
    }): async (Bool, Text) {

        var generalProgress: [MissionProgress] = [
            { missionType = #GamesCompleted; progress = 1; },
            { missionType = #DamageDealt; progress = playerStats.damageDealt },
            { missionType = #DamageTaken; progress = playerStats.damageTaken },
            { missionType = #EnergyUsed; progress = playerStats.energyUsed },
            { missionType = #UnitsDeployed; progress = playerStats.deploys },
            { missionType = #FactionPlayed; progress = playerStats.faction },
            { missionType = #GameModePlayed; progress = playerStats.gameMode },
            { missionType = #XPEarned; progress = playerStats.xpEarned },
            { missionType = #Kills; progress = playerStats.kills }
        ];

        if (playerStats.wonGame) {
            generalProgress := Array.append(generalProgress, [{ missionType = #GamesWon; progress = 1 }]);
        };

        Debug.print("[updateProgressManager] Updating general mission progress...");
        Debug.print("[updateProgressManager] General progress: " # debug_show(generalProgress));
        let (result1, message1) = await updateGeneralMissionProgress(user, generalProgress);
        Debug.print("[updateProgressManager] General mission progress update result: " # debug_show(result1) # ", message: " # message1);

        Debug.print("[updateProgressManager] Updating user-specific mission progress...");
        Debug.print("[updateProgressManager] Player stats: " # debug_show(playerStats));
        let (result2, message2) = await updateUserMissions(user, playerStats);
        Debug.print("[updateProgressManager] User-specific mission progress update result: " # debug_show(result2) # ", message: " # message2);

        let success = result1 and result2;
        let message = message1 # " | " # message2;

        return (success, message);
};


public shared (msg) func saveFinishedGame(matchID: MatchID, _playerStats: {
    secRemaining: Nat;
    energyGenerated: Nat;
    damageDealt: Nat;
    wonGame: Bool;
    botMode: Nat;
    deploys: Nat;
    damageTaken: Nat;
    damageCritic: Nat;
    damageEvaded: Nat;
    energyChargeRate: Nat;
    faction: Nat;
    energyUsed: Nat;
    gameMode: Nat;
    energyWasted: Nat;
    xpEarned: Nat;
    characterID: Nat;
    botDifficulty: Nat;
    kills: Nat;
    }): async (Bool, Text) {
    var _txt: Text = "";

    let playerStats = {
        secRemaining = _playerStats.secRemaining;
        energyGenerated = _playerStats.energyGenerated;
        damageDealt = _playerStats.damageDealt;
        wonGame = _playerStats.wonGame;
        playerId = msg.caller;
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

    Debug.print("[saveFinishedGame] Player stats: " # debug_show(playerStats));

    let isExistingMatch = switch (basicStats.get(matchID)) {
        case (null) { false };
        case (?_) { true };
    };

    let endingGame: (Bool, Bool, ?Principal) = await setGameOver(msg.caller);
    let isPartOfMatch = await isCallerPartOfMatch(matchID, msg.caller);
    if (not isPartOfMatch) {
        return (false, "You are not part of this match.");
    };

    if (isExistingMatch) {
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
        let newBasicStats: BasicStats = {
            playerStats = [playerStats];
        };
        basicStats.put(matchID, newBasicStats);

        let (_gameValid, validationMsg) = Validator.validateGame(300 - playerStats.secRemaining, playerStats.xpEarned);
        if (not _gameValid) {
            onValidation.put(matchID, newBasicStats);
            return (false, validationMsg);
        };

        let _winner = if (playerStats.wonGame) 1 else 0;
        let _looser = if (not playerStats.wonGame) 1 else 0;
        let _elo: Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);

        Debug.print("[saveFinishedGame] Calling updateProgressManager...");
        let (success, message) = await updateProgressManager(msg.caller, playerStats);
        Debug.print("[saveFinishedGame] updateProgressManager result: " # debug_show(success) # ", message: " # message);

        if (not success) {
            return (false, "Failed to update progress: " # message);
        };

        updatePlayerGameStats(msg.caller, playerStats, _winner, _looser);
        updateOverallStats(matchID, playerStats);

        let playerOpt = players.get(msg.caller);
        switch (playerOpt) {
            case (?player) {
                let updatedPlayer: Player = {
                    id = player.id;
                    username = player.username;
                    avatar = player.avatar;
                    description = player.description;
                    registrationDate = player.registrationDate;
                    level = Utils.calculateLevel(playerStats.xpEarned);
                    elo = player.elo;
                    friends = player.friends;
                };
                players.put(msg.caller, updatedPlayer);
            };
            case (null) {};
        };

        return (true, "Game saved: " # message);
    } else {
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

                let (_gameValid, validationMsg) = Validator.validateGame(300 - playerStats.secRemaining, playerStats.xpEarned);
                if (not _gameValid) {
                    onValidation.put(matchID, updatedBasicStats);
                    return (false, validationMsg);
                };

                let _winner = if (playerStats.wonGame) 1 else 0;
                let _looser = if (not playerStats.wonGame) 1 else 0;
                let _elo: Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);

                Debug.print("[saveFinishedGame] Calling updateProgressManager...");
                let (success, message) = await updateProgressManager(msg.caller, playerStats);
                Debug.print("[saveFinishedGame] updateProgressManager result: " # debug_show(success) # ", message: " # message);

                if (not success) {
                    return (false, "Failed to update progress: " # message);
                };

                updatePlayerGameStats(msg.caller, playerStats, _winner, _looser);
                updateOverallStats(matchID, playerStats);

                let playerOpt = players.get(msg.caller);
                switch (playerOpt) {
                    case (?player) {
                        let updatedPlayer: Player = {
                            id = player.id;
                            username = player.username;
                            avatar = player.avatar;
                            description = player.description;
                            registrationDate = player.registrationDate;
                            level = Utils.calculateLevel(playerStats.xpEarned);
                            elo = player.elo;
                            friends = player.friends;
                        };
                        players.put(msg.caller, updatedPlayer);
                    };
                    case (null) {};
                };

                return (true, _txt # " - Game saved: " # message);
            };
        };
    };
};







//----

// Players

    stable var _players: [(PlayerId, Player)] = [];
    var players: HashMap.HashMap<PlayerId, Player> = HashMap.fromIter(_players.vals(), 0, Principal.equal, Principal.hash);

    // Function to register a new player
    public shared ({ caller: PlayerId }) func registerPlayer(username: Username, avatar: AvatarID) : async (Bool, PlayerId, Bool, Text, Nat) {
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

                // Assign new missions to the user
                await assignGeneralMissions(PlayerId);

                // Create a user-specific hourly mission and capture the result
                let (missionSuccess, missionMessage, missionID) = await createUserMission(PlayerId);

                return (true, PlayerId, missionSuccess, missionMessage, missionID);
            };
            case (?_) {
                return (false, PlayerId, false, "User already exists", 0); // User already exists
            };
        };
    };

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
                totalKills = 0;
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

            let gamesPlayed = playerStats.gamesPlayed;
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


// Statistics

  // Nulls or Anons cannot use matchmaking (later add non registered players and Level req. + loss default inactivity)
  let NULL_PRINCIPAL: Principal = Principal.fromText("aaaaa-aa");
  let ANON_PRINCIPAL: Principal = Principal.fromText("2vxsx-fae");

  stable var _basicStats: [(MatchID, BasicStats)] = [];
  var basicStats: HashMap.HashMap<MatchID, BasicStats> = HashMap.fromIter(_basicStats.vals(), 0, Utils._natEqual, Utils._natHash);

  stable var _playerGamesStats: [(PlayerId, PlayerGamesStats)] = [];
  var playerGamesStats: HashMap.HashMap<PlayerId, PlayerGamesStats> = HashMap.fromIter(_playerGamesStats.vals(), 0, Principal.equal, Principal.hash);

  stable var _onValidation: [(MatchID, BasicStats)] = [];
  var onValidation: HashMap.HashMap<MatchID, BasicStats> = HashMap.fromIter(_onValidation.vals(), 0, Utils._natEqual, Utils._natHash);

  stable var _countedMatches: [(MatchID, Bool)] = [];
  var countedMatches: HashMap.HashMap<MatchID, Bool> = HashMap.fromIter(_countedMatches.vals(), 0, Utils._natEqual, Utils._natHash);


  stable var overallStats: OverallStats = {
      totalGamesPlayed: Nat = 0;
      totalGamesSP: Nat = 0;
      totalGamesMP: Nat = 0;
      totalDamageDealt: Nat = 0;
      totalTimePlayed: Nat = 0;
      totalKills: Nat = 0;
      totalEnergyGenerated: Nat = 0;
      totalEnergyUsed: Nat = 0;
      totalEnergyWasted: Nat = 0;
      totalXpEarned: Nat = 0;
      totalGamesWithFaction: [GamesWithFaction] = [];
      totalGamesGameMode: [GamesWithGameMode] = [];
      totalGamesWithCharacter: [GamesWithCharacter] = [];
  };

  func _initializeNewPlayerStats(_player: Principal): async (Bool, Text) {
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
          totalKills = 0;
          totalGamesWithFaction = [];
          totalGamesGameMode = [];
          totalGamesWithCharacter = [];
      };
      playerGamesStats.put(_player, _playerStats);
      return (true, "Player stats initialized");
  };

  func setGameOver(caller: Principal) : async (Bool, Bool, ?Principal) {
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

    func updatePlayerELO(PlayerId : PlayerId, won : Nat, otherPlayerId : ?PlayerId) : async Bool {
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

    func updateELOonPlayer(playerId : Principal, newELO : Float) : async Bool {
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

    // Helper function to check if the caller is part of the match
    func isCallerPartOfMatch(matchID: MatchID, caller: Principal) : async Bool {
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
    func updatePlayerGameStats(playerId: PlayerId, _playerStats: PlayerStats, _winner: Nat, _looser: Nat) {
        switch (playerGamesStats.get(playerId)) {
            case (null) {
                let _gs: PlayerGamesStats = {
                    gamesPlayed = 1;
                    gamesWon = _winner;
                    gamesLost = _looser;
                    energyGenerated = _playerStats.energyGenerated;
                    energyUsed = _playerStats.energyUsed;
                    energyWasted = _playerStats.energyWasted;
                    totalKills = _playerStats.kills;
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
                    _thisGameXP := _thisGameXP * 1;
                };
                if (_playerStats.gameMode == 1) {
                    _thisGameXP := _thisGameXP * 2;
                } else {
                    _thisGameXP := _thisGameXP * 1;
                };

                let _gs: PlayerGamesStats = {
                    gamesPlayed = _bs.gamesPlayed + 1;
                    gamesWon = _bs.gamesWon + _winner;
                    gamesLost = _bs.gamesLost + _looser;
                    energyGenerated = _bs.energyGenerated + _playerStats.energyGenerated;
                    energyUsed = _bs.energyUsed + _playerStats.energyUsed;
                    energyWasted = _bs.energyWasted + _playerStats.energyWasted;
                    totalKills = _bs.totalKills + _playerStats.kills;
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
    func updateOverallStats(matchID: MatchID, _playerStats: PlayerStats) {
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

        let maxGameTime: Nat = 300; // 5 minutes in seconds
        let timePlayed: Nat = maxGameTime - _playerStats.secRemaining;

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

  var ONE_SECOND : Nat64 = 1_000_000_000;
  stable var _matchID : Nat = 0;
  var inactiveSeconds : Nat64 = 30 * ONE_SECOND;

  stable var _searching : [(MatchID, MatchData)] = [];
  var searching : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_searching.vals(), 0, Utils._natEqual, Utils._natHash);

  stable var _playerStatus : [(PlayerId, MMPlayerStatus)] = [];
  var playerStatus : HashMap.HashMap<PlayerId, MMPlayerStatus> = HashMap.fromIter(_playerStatus.vals(), 0, Principal.equal, Principal.hash);

  stable var _inProgress : [(MatchID, MatchData)] = [];
  var inProgress : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_inProgress.vals(), 0, Utils._natEqual, Utils._natHash);

  stable var _finishedGames : [(MatchID, MatchData)] = [];
  var finishedGames : HashMap.HashMap<MatchID, MatchData> = HashMap.fromIter(_finishedGames.vals(), 0, Utils._natEqual, Utils._natHash);

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

    func structPlayerActiveNow(_p1 : MMInfo) : MMInfo {
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

    func structMatchData(_p1 : MMInfo, _p2 : ?MMInfo, _m : MatchData) : MatchData {
        let _md : MatchData = {
            matchID = _m.matchID;
            player1 = _p1;
            player2 = _p2;
            status = _m.status;
        };
        return _md;
    };

    func activatePlayerSearching(player : Principal, matchID : Nat) : Bool {
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
                averageEnergyGenerated = _p.energyGenerated / _p.gamesPlayed;
                averageEnergyUsed = _p.energyUsed / _p.gamesPlayed;
                averageEnergyWasted = _p.energyWasted / _p.gamesPlayed;
                averageDamageDealt = _p.totalDamageDealt / _p.gamesPlayed;
                averageKills = _p.totalKills / _p.gamesPlayed;
                averageXpEarned = _p.totalXpEarned / _p.gamesPlayed;
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
        xp: Nat;
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
    func _processUpgrade(nftID: TokenID, caller: Principal, _nftMetadata: [(Text, TypesICRC7.Metadata)]): async () {
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
                Debug.print("[upgradeNFT]Upgrade successful for NFT ID: " # Nat.toText(nftID) # " by caller: " # Principal.toText(caller));
            };
            case (#Err(_e)) {
                Debug.print("[upgradeNFT]Upgrade cost transfer failed: ");
            };
        };
    };

    // Function to execute NFT upgrade
    func _executeUpgrade(nftID: TokenID, caller: Principal, _nftMetadata: [(Text, TypesICRC7.Metadata)]): async () {
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
            case (#Ok(_)) Debug.print("[_executeUpgrade]NFT upgraded successfully.");
            case (#Err(_e)) Debug.print("[_executeUpgrade]NFT upgrade failed:");
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

                // Prepare mint arguments
                let _shardsArgs: TypesICRC1.Mint = {
                    to = { owner = caller; subaccount = null };
                    amount = shardsAmount;
                    memo = null;
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };

                let _fluxArgs: TypesICRC1.Mint = {
                    to = { owner = caller; subaccount = null };
                    amount = fluxAmount;
                    memo = null;
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };

                // Mint shards and flux tokens concurrently
                let shardsMintedFuture = async { await shards.mint(_shardsArgs) };
                let fluxMintedFuture = async { await flux.mint(_fluxArgs) };

                let shardsMinted = await shardsMintedFuture;
                let fluxMinted = await fluxMintedFuture;

                // Handle shards minting result
                let shardsResult = switch (shardsMinted) {
                    case (#Ok(_tid)) "{\"token\":\"Shards\", \"transaction_id\": " # Nat.toText(_tid) # ", \"amount\": " # Nat.toText(shardsAmount) # "}";
                    case (#Err(_e)) Utils.handleMintError("Shards", _e);
                };

                // Handle flux minting result
                let fluxResult = switch (fluxMinted) {
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

};