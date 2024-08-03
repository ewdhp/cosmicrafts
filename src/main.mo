//Imports
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
import TypesAchievements "TypesAchievements";
import Int64 "mo:base/Int64";
// import AchievementMissionsTemplate "AchievementMissionsTemplate";
import Validator "Validator";
import MissionOptions "MissionOptions";

shared actor class Cosmicrafts() {
  // Types
  public type PlayerId = Types.PlayerId;
  public type Username = Types.Username;
  public type AvatarID = Types.AvatarID;
  public type Description = Types.Description;
  public type RegistrationDate = Types.RegistrationDate;
  public type Level = Types.Level;
  public type Player = Types.Player;

  public type FriendRequest = Types.FriendRequest;
  public type MutualFriendship = Types.MutualFriendship;
  public type FriendDetails = Types.FriendDetails;
  public type PrivacySetting = Types.PrivacySetting;
  public type Notification = Types.Notification;
  public type UpdateTimestamps = Types.UpdateTimestamps;

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
  public type MatchID = Types.MatchID;

  public type MissionType = Types.MissionType;
  public type RewardType = Types.MissionRewardType;
  public type Mission = Types.Mission;
  public type MissionsUser = Types.MissionsUser;
  public type MissionProgress = Types.MissionProgress;
  public type MissionTemplate = Types.MissionTemplate;
  public type RewardPool = Types.RewardPool;
  public type MissionOption = Types.MissionOption;

  public type IndividualAchievement = TypesAchievements.IndividualAchievement;
  public type Achievement = TypesAchievements.Achievement;
  public type AchievementCategory = TypesAchievements.AchievementCategory;
  public type AchievementType = TypesAchievements.AchievementType;
  public type AchievementRewardsType = TypesAchievements.AchievementRewardsType;
  public type AchievementReward = TypesAchievements.AchievementReward;
  public type AchievementTier = TypesAchievements.AchievementTier;
  public type AchievementProgress = TypesAchievements.AchievementProgress;
  public type IndividualAchievementProgress = TypesAchievements.IndividualAchievementProgress;

  type AchievementName = Text;
  type IndividualAchievementList = [Nat];
  type RequiredProgress = Nat;
  type CategoryId = Nat;

  //Timer
  public type Duration = Timer.Duration;
  public type TimerId = Timer.TimerId;

  //ICRC
  public type TokenID = Types.TokenID;

  //--
  // Admin Tools

  // mint deck should only be called once per PID

  // migrations BEFORE deployment

  stable var _cosmicraftsPrincipal : Principal = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai");
  let ADMIN_PRINCIPAL = Principal.fromText("vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae");

  // Define an enum for the different functions
  public type AdminFunction = {
    #CreateMission : (Text, MissionType, RewardType, Nat, Nat, Nat64);
    #CreateMissionsPeriodically : ();
    #MintChest : (Principal, Nat);
  };

  public shared ({ caller }) func adminManagement(funcToCall : AdminFunction) : async (Bool, Text) {
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
        case (#MintChest(PlayerId, rarity)) {
          let (success, message) = await mintChest(PlayerId, rarity);
          return (success, message);
        };
      };
    } else {
      return (false, "Access denied: Only admin can call this function.");
    };
  };

  //--
  // Missions

  let ONE_HOUR : Nat64 = 60 * 60 * 1_000_000_000;
  let ONE_DAY : Nat64 = 60 * 60 * 24 * 1_000_000_000;
  let ONE_WEEK : Nat64 = 60 * 60 * 24 * 7 * 1_000_000_000; // 60 secs * 60 minutes * 24 hours * 7

  var lastDailyMissionCreationTime : Nat64 = 0;
  var lastWeeklyMissionCreationTime : Nat64 = 0;
  stable var lastDailyFreeRewardMissionCreationTime : Nat64 = 0;

  stable var shuffledDailyIndices : [Nat] = [];
  stable var currentDailyIndex : Nat = 0;

  stable var shuffledHourlyIndices : [Nat] = [];
  stable var currentHourlyIndex : Nat = 0;

  stable var shuffledWeeklyIndices : [Nat] = [];
  stable var currentWeeklyIndex : Nat = 0;

  stable var shuffledDailyFreeRewardIndices : [Nat] = [];
  stable var currentDailyFreeRewardIndex : Nat = 0;

  func initializeShuffledHourlyMissions() : async () {
    let indices : [Nat] = Array.tabulate(MissionOptions.hourlyMissions.size(), func(i : Nat) : Nat { i });
    shuffledHourlyIndices := await Utils.shuffleArray(indices);
    currentHourlyIndex := 0;
  };

  func initializeShuffledDailyMissions() : async () {
    let indices : [Nat] = Array.tabulate(MissionOptions.dailyMissions.size(), func(i : Nat) : Nat { i });
    shuffledDailyIndices := await Utils.shuffleArray(indices);
    currentDailyIndex := 0;
  };

  func initializeShuffledWeeklyMissions() : async () {
    let indices : [Nat] = Array.tabulate(MissionOptions.weeklyMissions.size(), func(i : Nat) : Nat { i });
    shuffledWeeklyIndices := await Utils.shuffleArray(indices);
    currentWeeklyIndex := 0;
  };

  func initializeShuffledDailyFreeRewardMissions() : async () {
    let indices : [Nat] = Array.tabulate(MissionOptions.dailyFreeReward.size(), func(i : Nat) : Nat { i });
    shuffledDailyFreeRewardIndices := await Utils.shuffleArray(indices);
    currentDailyFreeRewardIndex := 0;
  };

  func createDailyMissions() : async [(Bool, Text, Nat)] {
    var results : [(Bool, Text, Nat)] = [];

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

  func createWeeklyMissions() : async [(Bool, Text, Nat)] {
    var results : [(Bool, Text, Nat)] = [];

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

  func createDailyFreeRewardMissions() : async [(Bool, Text, Nat)] {
    var results : [(Bool, Text, Nat)] = [];

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

  func createSingleConcurrentMission(template : Types.MissionTemplate) : async (Bool, Text, Nat) {
    let rewardAmount = await getRandomReward(template.minReward, template.maxReward);
    return await createGeneralMission(
      template.name,
      template.missionType,
      template.rewardType,
      rewardAmount,
      template.total,
      template.hoursActive,
    );
  };

  func createMissionsPeriodically() : async () {
    let now = Nat64.fromIntWrap(Time.now());
    Debug.print("[createMissionsPeriodically] Current time: " # Nat64.toText(now));

    // Create and assign daily missions
    if (now - lastDailyMissionCreationTime >= ONE_DAY) {
      let dailyResults = await createDailyMissions();
      await Utils.logMissionResults(dailyResults, "Daily");
      lastDailyMissionCreationTime := now;
    };

    // Create and assign weekly missions
    if (now - lastWeeklyMissionCreationTime >= ONE_WEEK) {
      let weeklyResults = await createWeeklyMissions();
      await Utils.logMissionResults(weeklyResults, "Weekly");
      lastWeeklyMissionCreationTime := now;
    };

    // Create and assign daily free reward missions every 4 hours
    if (now - lastDailyFreeRewardMissionCreationTime >= ONE_HOUR * 4) {
      let dailyFreeResults = await createDailyFreeRewardMissions();
      await Utils.logMissionResults(dailyFreeResults, "Daily Free Reward");
      lastDailyFreeRewardMissionCreationTime := now;
    };

    // Set the timer to call this function again after 1 hour
    let _ : Timer.TimerId = Timer.setTimer<system>(
      #seconds(60 * 60),
      func() : async () {
        await createMissionsPeriodically();
      },
    );
  };

  func getRandomReward(minReward : Nat, maxReward : Nat) : async Nat {
    let randomBytes = await Random.blob(); // Generating random bytes
    let byteArray = Blob.toArray(randomBytes);
    let randomByte = byteArray[0]; // Use the first byte for randomness
    let range = maxReward - minReward + 1;
    let randomValue = Nat8.toNat(randomByte) % range;
    return minReward + randomValue;
  };

  //----
  // General Missions
  stable var generalMissionIDCounter : Nat = 1;
  stable var _generalUserProgress : [(Principal, [MissionsUser])] = [];
  stable var _missions : [(Nat, Mission)] = [];
  stable var _activeMissions : [(Nat, Mission)] = [];
  stable var _claimedRewards : [(Principal, [Nat])] = [];

  // HashMaps for General Missions
  var missions : HashMap.HashMap<Nat, Mission> = HashMap.fromIter(_missions.vals(), 0, Utils._natEqual, Utils._natHash);
  var activeMissions : HashMap.HashMap<Nat, Mission> = HashMap.fromIter(_activeMissions.vals(), 0, Utils._natEqual, Utils._natHash);
  var claimedRewards : HashMap.HashMap<Principal, [Nat]> = HashMap.fromIter(_claimedRewards.vals(), 0, Principal.equal, Principal.hash);
  var generalUserProgress : HashMap.HashMap<Principal, [MissionsUser]> = HashMap.fromIter(_generalUserProgress.vals(), 0, Principal.equal, Principal.hash);

  // Function to create a new general mission
  func createGeneralMission(name : Text, missionType : MissionType, rewardType : RewardType, rewardAmount : Nat, total : Nat, hoursActive : Nat64) : async (Bool, Text, Nat) {
    let id = generalMissionIDCounter;
    generalMissionIDCounter += 1;

    let now = Nat64.fromIntWrap(Time.now());
    let duration = ONE_HOUR * hoursActive;
    let endDate = now + duration;

    let newMission : Mission = {
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
  func updateGeneralMissionProgress(user : Principal, missionsProgress : [MissionProgress]) : async (Bool, Text) {
    Debug.print("[updateGeneralMissionProgress] Updating general mission progress for user: " # Principal.toText(user));
    Debug.print("[updateGeneralMissionProgress] Missions progress: " # debug_show (missionsProgress));

    var userMissions : [MissionsUser] = switch (generalUserProgress.get(user)) {
      case (null) { [] };
      case (?missions) { missions };
    };

    Debug.print("[updateGeneralMissionProgress] User's current missions: " # debug_show (userMissions));

    let now : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    let updatedMissions = Buffer.Buffer<MissionsUser>(userMissions.size());

    for (mission in userMissions.vals()) {
      Debug.print("[updateGeneralMissionProgress] Processing mission: " # debug_show (mission));
      if (mission.finished) {
        updatedMissions.add(mission);
      } else {
        var updatedMission = mission;
        for (progress in missionsProgress.vals()) {
          if (mission.missionType == progress.missionType) {
            let updatedProgress = mission.progress + progress.progress;
            Debug.print("[updateGeneralMissionProgress] Updated progress for missionType " # debug_show (mission.missionType) # ": " # debug_show (updatedProgress));
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
    Debug.print("[updateGeneralMissionProgress] Updated user missions: " # debug_show (generalUserProgress.get(user)));
    return (true, "Progress added successfully to general missions");
  };

  // Function to assign new general missions to a user
  func assignGeneralMissions(user : Principal) : async () {
    Debug.print("[assignGeneralMissions] Assigning new general missions to user: " # Principal.toText(user));

    var userMissions : [MissionsUser] = switch (generalUserProgress.get(user)) {
      case (null) { [] };
      case (?missions) { missions };
    };

    Debug.print("[assignGeneralMissions] User missions before update: " # debug_show (userMissions));

    var claimedRewardsForUser : [Nat] = switch (claimedRewards.get(user)) {
      case (null) { [] };
      case (?claimed) { claimed };
    };

    let now = Nat64.fromNat(Int.abs(Time.now()));
    let buffer = Buffer.Buffer<MissionsUser>(0);

    // Remove expired or claimed missions
    for (mission in userMissions.vals()) {
      if (mission.expiration >= now and not Utils.arrayContains<Nat>(claimedRewardsForUser, mission.id_mission, Utils._natEqual)) {
        buffer.add(mission);
      };
    };

    // Collect IDs of current missions to avoid duplication
    let currentMissionIds = Buffer.Buffer<Nat>(buffer.size());
    for (mission in buffer.vals()) {
      currentMissionIds.add(mission.id_mission);
    };

    // Add new active missions to the user
    for ((id, mission) in activeMissions.entries()) {
      if (not Utils.arrayContains<Nat>(Buffer.toArray(currentMissionIds), id, Utils._natEqual) and not Utils.arrayContains<Nat>(claimedRewardsForUser, id, Utils._natEqual)) {
        let isDailyFreeReward = checkIfDailyFreeRewardMission(mission); // Check if the mission is a daily free reward mission
        buffer.add({
          id_mission = id;
          reward_amount = mission.reward_amount;
          start_date = mission.start_date;
          progress = 0; // Initialize with 0 progress
          finish_date = 0; // Initialize finish date to 0
          expiration = mission.end_date;
          missionType = mission.missionType;
          finished = isDailyFreeReward; // Set finished based on mission type
          reward_type = mission.reward_type;
          total = mission.total;
        });
      };
    };

    // Update user missions
    generalUserProgress.put(user, Buffer.toArray(buffer));
    Debug.print("[assignGeneralMissions] User missions after update: " # debug_show (Buffer.toArray(buffer)));
  };

  // Helper function to check if a mission is a daily free reward mission
  func checkIfDailyFreeRewardMission(mission : Mission) : Bool {
    for (template in MissionOptions.dailyFreeReward.vals()) {
      if (mission.name == template.name and mission.missionType == template.missionType and mission.reward_type == template.rewardType) {
        return true;
      };
    };
    return false;
  };

  // Function to get general missions for a user
  public shared ({ caller }) func getGeneralMissions() : async [MissionsUser] {
    // Step 1: Assign new general missions to the user
    await assignGeneralMissions(caller);

    // Step 2: Search for active general missions assigned to the user
    let activeMissions : [MissionsUser] = await searchActiveGeneralMissions(caller);

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
  public query func searchActiveGeneralMissions(user : Principal) : async [MissionsUser] {
    let now : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    var userMissions : [MissionsUser] = switch (generalUserProgress.get(user)) {
      case (null) { [] };
      case (?missions) { missions };
    };

    var claimedRewardsForUser : [Nat] = switch (claimedRewards.get(user)) {
      case (null) { [] };
      case (?claimed) { claimed };
    };

    let activeMissions = Buffer.Buffer<MissionsUser>(0);
    for (mission in userMissions.vals()) {
      if (mission.expiration >= now and not Utils.arrayContains<Nat>(claimedRewardsForUser, mission.id_mission, Utils._natEqual)) {
        activeMissions.add(mission);
      };
    };

    return Buffer.toArray(activeMissions);
  };

  // Function to get the progress of a specific general mission for a user
  public query func getGeneralMissionProgress(user : Principal, missionID : Nat) : async ?MissionsUser {
    let userMissions : [MissionsUser] = switch (generalUserProgress.get(user)) {
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
  public shared (msg) func claimGeneralReward(idMission : Nat) : async (Bool, Text) {
    let missionOpt = await getGeneralMissionProgress(msg.caller, idMission);
    switch (missionOpt) {
      case (null) {
        return (false, "Mission not assigned");
      };
      case (?mission) {
        let currentTime : Nat64 = Nat64.fromNat(Int.abs(Time.now()));

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
          var userMissions : [MissionsUser] = switch (generalUserProgress.get(msg.caller)) {
            case (null) { [] };
            case (?missions) { missions };
          };
          let updatedMissions = Buffer.Buffer<MissionsUser>(userMissions.size());
          for (r in userMissions.vals()) {
            if (r.id_mission != idMission) {
              updatedMissions.add(r);
            };
          };
          generalUserProgress.put(msg.caller, Buffer.toArray(updatedMissions));

          // Add claimed reward to claimedRewards
          claimedRewards.put(msg.caller, Array.append(claimedRewardsForUser, [idMission]));
        };
        return (success, message);
      };
    };
  };

  func mintGeneralRewards(mission : MissionsUser, caller : Principal) : async (Bool, Text) {
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
        let mintArgs : TypesICRC7.MintArgs = {
          to = { owner = caller; subaccount = null };
          token_id = uuid;
          metadata = Utils.getChestMetadata(mission.reward_amount);
        };
        let mintResult = await chests.mint(mintArgs);
        switch (mintResult) {
          case (#Ok(_transactionID)) {
            await updateMintedChests(caller, uuid);
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
        let mintArgs : TypesICRC1.Mint = {
          to = { owner = caller; subaccount = null };
          amount = mission.reward_amount;
          memo = null;
          created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };
        let mintResult = await flux.mint(mintArgs);
        switch (mintResult) {
          case (#Ok(_transactionID)) {
            await updateMintedFlux(caller, mission.reward_amount);
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
        let mintArgs : TypesICRC1.Mint = {
          to = { owner = caller; subaccount = null };
          amount = mission.reward_amount;
          memo = null;
          created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };
        let mintResult = await shards.mint(mintArgs);
        switch (mintResult) {
          case (#Ok(_transactionID)) {
            await updateMintedShards(caller, mission.reward_amount);
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

  //Stable Variables
  stable var _userMissionProgress : [(Principal, [MissionsUser])] = [];
  stable var _userMissions : [(Principal, [Mission])] = [];
  stable var _userMissionCounters : [(Principal, Nat)] = [];
  stable var _userClaimedRewards : [(Principal, [Nat])] = [];

  // HashMaps for User-Specific Missions
  var userMissionProgress : HashMap.HashMap<Principal, [MissionsUser]> = HashMap.fromIter(_userMissionProgress.vals(), 0, Principal.equal, Principal.hash);
  var userMissions : HashMap.HashMap<Principal, [Mission]> = HashMap.fromIter(_userMissions.vals(), 0, Principal.equal, Principal.hash);
  var userMissionCounters : HashMap.HashMap<Principal, Nat> = HashMap.fromIter(_userMissionCounters.vals(), 0, Principal.equal, Principal.hash);
  var userClaimedRewards : HashMap.HashMap<Principal, [Nat]> = HashMap.fromIter(_userClaimedRewards.vals(), 0, Principal.equal, Principal.hash);

  // Function to create a new user-specific mission
  public func createUserMission(user : PlayerId) : async (Bool, Text, Nat) {
    Debug.print("[createUserMission] Start creating mission for user: " # Principal.toText(user));

    var userMissionsList : [Mission] = switch (userMissions.get(user)) {
      case (null) { [] };
      case (?missions) { missions };
    };

    var userSpecificProgressList : [MissionsUser] = switch (userMissionProgress.get(user)) {
      case (null) { [] };
      case (?progress) { progress };
    };

    Debug.print("[createUserMission] User Missions: " # debug_show (userMissionsList));
    Debug.print("[createUserMission] User Progress List: " # debug_show (userSpecificProgressList));

    if (userSpecificProgressList.size() > 0) {
      let lastMissionProgress = userSpecificProgressList[userSpecificProgressList.size() - 1];
      let currentTime = Nat64.fromNat(Int.abs(Time.now()));

      Debug.print("[createUserMission] Last Mission Progress: " # debug_show (lastMissionProgress));
      Debug.print("[createUserMission] Current Time: " # debug_show (currentTime));

      if (not lastMissionProgress.finished and currentTime <= lastMissionProgress.expiration) {
        Debug.print("[createUserMission] Current mission is still active: " # debug_show (lastMissionProgress));
        return (false, "Current mission is still active", lastMissionProgress.id_mission);
      } else {
        Debug.print("[createUserMission] Current mission is not active or is finished");
      };
    };

    if (shuffledHourlyIndices.size() == 0 or currentHourlyIndex >= shuffledHourlyIndices.size()) {
      await initializeShuffledHourlyMissions();
    };

    let index = shuffledHourlyIndices[currentHourlyIndex];
    let template = MissionOptions.hourlyMissions[index];
    let rewardAmount = await getRandomReward(template.minReward, template.maxReward);

    currentHourlyIndex += 1;

    let missionIDCounter = switch (userMissionCounters.get(user)) {
      case (null) { 0 };
      case (?counter) { counter };
    };

    let now = Nat64.fromNat(Int.abs(Time.now()));
    let newMission : Mission = {
      id = missionIDCounter;
      name = template.name;
      missionType = template.missionType;
      reward_type = template.rewardType;
      reward_amount = rewardAmount;
      start_date = now;
      end_date = now + (template.hoursActive * ONE_HOUR);
      total = template.total;
    };

    Debug.print("[createUserMission] New Mission: " # debug_show (newMission));

    userMissionCounters.put(user, missionIDCounter + 1);
    userMissionsList := Array.append(userMissionsList, [newMission]);
    userMissions.put(user, userMissionsList);

    Debug.print("[createUserMission] Mission created successfully");
    await assignUserMissions(user);

    return (true, "User-specific mission created.", newMission.id);
  };

  // Function to update progress for user-specific missions
  func updateUserMissionsProgress(
    user : Principal,
    playerStats : {
      secRemaining : Nat;
      energyGenerated : Nat;
      damageDealt : Nat;
      damageTaken : Nat;
      energyUsed : Nat;
      deploys : Nat;
      faction : Nat;
      gameMode : Nat;
      xpEarned : Nat;
      kills : Nat;
      wonGame : Bool;
    },
  ) : async (Bool, Text) {

    Debug.print("[updateUserMissions] Updating user-specific mission progress for user: " # Principal.toText(user));
    Debug.print("[updateUserMissions] Player stats: " # debug_show (playerStats));

    var userSpecificProgressList = switch (userMissionProgress.get(user)) {
      case (null) { [] };
      case (?progress) { progress };
    };

    Debug.print("[updateUserMissions] User's current missions: " # debug_show (userSpecificProgressList));

    let now : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    let updatedMissions = Buffer.Buffer<MissionsUser>(userSpecificProgressList.size());

    for (mission in userSpecificProgressList.vals()) {
      Debug.print("[updateUserMissions] Processing mission: " # debug_show (mission));
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
            updatedMission := {
              mission with progress = mission.progress + playerStats.damageDealt
            };
          };
          case (#DamageTaken) {
            updatedMission := {
              mission with progress = mission.progress + playerStats.damageTaken
            };
          };
          case (#EnergyUsed) {
            updatedMission := {
              mission with progress = mission.progress + playerStats.energyUsed
            };
          };
          case (#UnitsDeployed) {
            updatedMission := {
              mission with progress = mission.progress + playerStats.deploys
            };
          };
          case (#FactionPlayed) {
            updatedMission := {
              mission with progress = mission.progress + playerStats.faction
            };
          };
          case (#GameModePlayed) {
            updatedMission := {
              mission with progress = mission.progress + playerStats.gameMode
            };
          };
          case (#XPEarned) {
            updatedMission := {
              mission with progress = mission.progress + playerStats.xpEarned
            };
          };
          case (#Kills) {
            updatedMission := {
              mission with progress = mission.progress + playerStats.kills
            };
          };
        };

        Debug.print("[updateUserMissions] Updated mission progress: " # debug_show (updatedMission.progress));

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
    Debug.print("[updateUserMissions] Updated user missions: " # debug_show (userMissionProgress.get(user)));
    return (true, "Progress updated successfully in user-specific missions");
  };

  // Function to assign new user-specific missions to a user
  func assignUserMissions(user : PlayerId) : async () {
    Debug.print("[assignUserMissions] Assigning new user-specific missions to user: " # Principal.toText(user));

    var userSpecificProgressList : [MissionsUser] = switch (userMissionProgress.get(user)) {
      case (null) { [] };
      case (?missions) { missions };
    };

    Debug.print("[assignUserMissions] User missions before update: " # debug_show (userSpecificProgressList));

    var claimedRewardsForUser : [Nat] = switch (userClaimedRewards.get(user)) {
      case (null) { [] };
      case (?claimed) { claimed };
    };

    let now = Nat64.fromNat(Int.abs(Time.now()));
    let buffer = Buffer.Buffer<MissionsUser>(0);

    // Remove expired or claimed missions
    for (mission in userSpecificProgressList.vals()) {
      if (mission.expiration >= now and not Utils.arrayContains<Nat>(claimedRewardsForUser, mission.id_mission, Utils._natEqual)) {
        buffer.add(mission);
      };
    };

    // Collect IDs of current missions to avoid duplication
    let currentMissionIds = Buffer.Buffer<Nat>(buffer.size());
    for (mission in buffer.vals()) {
      currentMissionIds.add(mission.id_mission);
    };

    // Check if the user has missions and add new active missions to the user
    switch (userMissions.get(user)) {
      case (null) {};
      case (?missions) {
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
          };
        };
      };
    };

    userMissionProgress.put(user, Buffer.toArray(buffer));
    Debug.print("[assignUserMissions] User missions after update: " # debug_show (userMissionProgress.get(user)));
  };

  // Function to get user-specific missions for a user
  public shared ({ caller }) func getUserMissions() : async [MissionsUser] {
    // Step 1: Assign new user-specific missions to the user
    await assignUserMissions(caller);

    // Step 2: Search for active user-specific missions assigned to the user
    let activeMissions : [MissionsUser] = await searchActiveUserMissions(caller);

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
  public query func searchActiveUserMissions(user : PlayerId) : async [MissionsUser] {
    let now : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
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
      };
    };

    return Buffer.toArray(activeMissions);
  };

  // Function to get the progress of a user-specific mission
  public query func getUserMissionProgress(user : PlayerId, missionID : Nat) : async ?MissionsUser {
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
  public shared (msg) func claimUserReward(idMission : Nat) : async (Bool, Text) {
    let missionOpt = await getUserMissionProgress(msg.caller, idMission);
    switch (missionOpt) {
      case (null) {
        return (false, "Mission not assigned");
      };
      case (?mission) {
        let currentTime : Nat64 = Nat64.fromNat(Int.abs(Time.now()));

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
            };
          };
          userMissionProgress.put(msg.caller, Buffer.toArray(updatedMissions));

          // Add claimed reward to userClaimedRewards
          userClaimedRewards.put(msg.caller, Array.append(claimedRewardsForUser, [idMission]));
        };
        return (success, message);
      };
    };
  };

  func mintUserRewards(mission : MissionsUser, caller : Principal) : async (Bool, Text) {
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
        let mintArgs : TypesICRC7.MintArgs = {
          to = { owner = caller; subaccount = null };
          token_id = uuid;
          metadata = Utils.getChestMetadata(mission.reward_amount);
        };
        let mintResult = await chests.mint(mintArgs);
        switch (mintResult) {
          case (#Ok(_transactionID)) {
            await updateMintedChests(caller, uuid);
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
        let mintArgs : TypesICRC1.Mint = {
          to = { owner = caller; subaccount = null };
          amount = mission.reward_amount;
          memo = null;
          created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };
        let mintResult = await flux.mint(mintArgs);
        switch (mintResult) {
          case (#Ok(_transactionID)) {
            await updateMintedFlux(caller, mission.reward_amount);
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
        let mintArgs : TypesICRC1.Mint = {
          to = { owner = caller; subaccount = null };
          amount = mission.reward_amount;
          memo = null;
          created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };
        let mintResult = await shards.mint(mintArgs);
        switch (mintResult) {
          case (#Ok(_transactionID)) {
            await updateMintedShards(caller, mission.reward_amount);
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

  //--
  // Achievements

  // Stable Variables
  stable var individualAchievementIDCounter : Nat = 1;
  stable var achievementIDCounter : Nat = 1;
  stable var categoryIDCounter : Nat = 1;

  stable var _individualAchievements : [(Nat, IndividualAchievement)] = [];
  stable var _achievements : [(Nat, Achievement)] = [];
  stable var _categories : [(Nat, AchievementCategory)] = [];

  stable var _achievementProgress : [(PlayerId, [AchievementProgress])] = [];
  stable var _playerAchievements : [(PlayerId, [Nat])] = [];
  stable var _categoryProgress : [(PlayerId, [AchievementProgress])] = [];
  stable var _claimedAchievementRewards : [(PlayerId, [Nat])] = []; // Added this line

  // HashMaps
  var individualAchievements : HashMap.HashMap<Nat, IndividualAchievement> = HashMap.fromIter(_individualAchievements.vals(), 0, Utils._natEqual, Utils._natHash);
  var achievements : HashMap.HashMap<Nat, Achievement> = HashMap.fromIter(_achievements.vals(), 0, Utils._natEqual, Utils._natHash);
  var categories : HashMap.HashMap<Nat, AchievementCategory> = HashMap.fromIter(_categories.vals(), 0, Utils._natEqual, Utils._natHash);
  var achievementProgress : HashMap.HashMap<PlayerId, [AchievementProgress]> = HashMap.fromIter(_achievementProgress.vals(), 0, Principal.equal, Principal.hash);
  var playerAchievements : HashMap.HashMap<PlayerId, [Nat]> = HashMap.fromIter(_playerAchievements.vals(), 0, Principal.equal, Principal.hash);
  var categoryProgress : HashMap.HashMap<PlayerId, [AchievementProgress]> = HashMap.fromIter(_categoryProgress.vals(), 0, Principal.equal, Principal.hash);
  var claimedAchievementRewards : HashMap.HashMap<PlayerId, [Nat]> = HashMap.fromIter(_claimedAchievementRewards.vals(), 0, Principal.equal, Principal.hash); // Added this line

  func determineTier(progress : Nat, requiredProgress : Nat) : TypesAchievements.AchievementTier {
    let progressPercentage = (progress * 100) / requiredProgress;
    if (progressPercentage >= 100) {
      return #Legend;
    } else if (progressPercentage >= 80) {
      return #Master;
    } else if (progressPercentage >= 60) {
      return #Diamond;
    } else if (progressPercentage >= 40) {
      return #Platinum;
    } else if (progressPercentage >= 20) {
      return #Gold;
    } else if (progressPercentage >= 10) {
      return #Silver;
    } else {
      return #Bronze;
    };
  };

  public func createIndividualAchievement(
    name : Text,
    achievementType : TypesAchievements.AchievementType,
    requiredProgress : Nat,
    rewards : [TypesAchievements.AchievementReward],
    achievementId : Nat,
  ) : async (Bool, Text, Nat) {
    let id = individualAchievementIDCounter;
    individualAchievementIDCounter += 1;

    let newIndividualAchievement : TypesAchievements.IndividualAchievement = {
      id = id;
      name = name;
      achievementType = achievementType;
      requiredProgress = requiredProgress;
      progress = 0;
      completed = false;
      reward = rewards; // Allowing multiple rewards
      achievementId = achievementId;
    };

    individualAchievements.put(id, newIndividualAchievement);
    Debug.print("[createIndividualAchievement] Individual Achievement created with ID: " # Nat.toText(id));

    return (true, "Individual Achievement created successfully", id);
  };

  public func createAchievement(
    name : Text,
    individualAchievements : [Nat],
    requiredProgress : Nat,
    categoryId : Nat,
    rewards : [TypesAchievements.AchievementReward],
  ) : async (Bool, Text, Nat) {
    let id = achievementIDCounter;
    achievementIDCounter += 1;

    let newAchievement : TypesAchievements.Achievement = {
      id = id;
      name = name;
      individualAchievements = individualAchievements;
      tier = determineTier(0, requiredProgress); // Initial tier based on zero progress
      progress = 0;
      requiredProgress = requiredProgress;
      categoryId = categoryId;
      reward = rewards; // Allowing multiple rewards
      completed = false;
    };

    achievements.put(id, newAchievement);
    Debug.print("[createAchievement] Achievement created with ID: " # Nat.toText(id));

    return (true, "Achievement created successfully", id);
  };

  public func createCategory(
    name : Text,
    achievements : [Nat],
    requiredProgress : Nat,
    rewards : [TypesAchievements.AchievementReward],
  ) : async (Bool, Text, Nat) {
    let id = categoryIDCounter;
    categoryIDCounter += 1;

    let newCategory : TypesAchievements.AchievementCategory = {
      id = id;
      name = name;
      achievements = achievements;
      tier = determineTier(0, requiredProgress); // Initial tier based on zero progress
      progress = 0;
      requiredProgress = requiredProgress;
      reward = rewards; // Allowing multiple rewards
      completed = false;
    };

    categories.put(id, newCategory);
    Debug.print("[createCategory] Category created with ID: " # Nat.toText(id));

    return (true, "Category created successfully", id);
  };

  public func updateIndividualAchievementProgress(
    user : PlayerId,
    progressList : [AchievementProgress],
  ) : async (Bool, Text) {
    Debug.print("[updateIndividualAchievementProgress] Updating achievement progress for user: " # Principal.toText(user));

    var userProgress : [AchievementProgress] = switch (achievementProgress.get(user)) {
      case (null) { [] };
      case (?progress) { progress };
    };

    Debug.print("[updateIndividualAchievementProgress] User's current achievements: " # debug_show (userProgress));

    let updatedProgress = Buffer.Buffer<AchievementProgress>(userProgress.size());

    for (newProgress in progressList.vals()) {
      var updated = false;
      for (progress in userProgress.vals()) {
        if (progress.achievementId == newProgress.achievementId) {
          let combinedProgress = progress.progress + newProgress.progress;
          let individualAchievement = individualAchievements.get(newProgress.achievementId);
          switch (individualAchievement) {
            case (?indAch) {
              let isCompleted = combinedProgress >= indAch.requiredProgress;
              updatedProgress.add({
                achievementId = progress.achievementId;
                playerId = progress.playerId;
                progress = if (isCompleted) indAch.requiredProgress else combinedProgress;
                completed = isCompleted;
              });
              if (isCompleted) {
                let _ = await updateGeneralAchievementProgress(user, indAch.achievementId);
              };
              updated := true;
            };
            case (null) {};
          };
        };
      };
      if (not updated) {
        updatedProgress.add(newProgress);
      };
    };

    achievementProgress.put(user, Buffer.toArray(updatedProgress));
    Debug.print("[updateIndividualAchievementProgress] Updated user achievements: " # debug_show (achievementProgress.get(user)));
    return (true, "Achievement progress updated successfully");
  };

  public func updateGeneralAchievementProgress(
    user : PlayerId,
    achievementId : Nat,
  ) : async (Bool, Text) {
    let achievementOpt = achievements.get(achievementId);
    switch (achievementOpt) {
      case (null) return (false, "Achievement not found");
      case (?achievement) {
        let individualAchievementIds = achievement.individualAchievements;
        var totalProgress : Nat = 0;
        var allCompleted = true;

        for (indAchId in individualAchievementIds.vals()) {
          let indAchOpt = individualAchievements.get(indAchId);
          switch (indAchOpt) {
            case (?indAch) {
              totalProgress += indAch.progress;
              if (not indAch.completed) {
                allCompleted := false;
              };
            };
            case (null) allCompleted := false;
          };
        };

        let isCompleted = totalProgress >= achievement.requiredProgress and allCompleted;
        if (isCompleted) {
          let _ = await updateCategoryProgress(user, achievement.categoryId);
        };

        achievements.put(
          achievementId,
          {
            achievement with
            progress = totalProgress;
            completed = isCompleted;
          },
        );

        return (true, "General achievement progress updated successfully");
      };
    };
  };

  public func updateCategoryProgress(
    user : PlayerId,
    categoryId : Nat,
  ) : async (Bool, Text) {
    let categoryOpt = categories.get(categoryId);
    switch (categoryOpt) {
      case (null) return (false, "Category not found");
      case (?category) {
        let achievementsList = category.achievements;
        var totalProgress : Nat = 0;
        var allCompleted = true;

        var userProgress : [AchievementProgress] = switch (categoryProgress.get(user)) {
          case (null) { [] };
          case (?progress) { progress };
        };

        for (achId in achievementsList.vals()) {
          let achOpt = achievements.get(achId);
          switch (achOpt) {
            case (?ach) {
              totalProgress += ach.progress;
              if (not ach.completed) {
                allCompleted := false;
              };
            };
            case (null) allCompleted := false;
          };
        };

        let isCompleted = totalProgress >= category.requiredProgress and allCompleted;

        var updatedProgressList = Buffer.Buffer<AchievementProgress>(userProgress.size());
        var found = false;
        for (p in userProgress.vals()) {
          if (p.achievementId == categoryId) {
            updatedProgressList.add({
              achievementId = p.achievementId;
              playerId = p.playerId;
              progress = totalProgress;
              completed = isCompleted;
            });
            found := true;
          } else {
            updatedProgressList.add(p);
          };
        };
        if (not found) {
          updatedProgressList.add({
            achievementId = categoryId;
            playerId = user;
            progress = totalProgress;
            completed = isCompleted;
          });
        };

        categoryProgress.put(user, Buffer.toArray(updatedProgressList));

        categories.put(
          categoryId,
          {
            category with
            progress = totalProgress;
            completed = isCompleted;
          },
        );

        return (true, "Category progress updated successfully");
      };
    };
  };

  // Function to assign achievements to a user
  public func assignAchievementsToUser(user : PlayerId) : async () {
    Debug.print("[assignAchievementsToUser] Assigning achievements to user: " # Principal.toText(user));

    var userAchievementsList : [Nat] = switch (playerAchievements.get(user)) {
      case (null) { [] };
      case (?achievements) { achievements };
    };

    // Assign individual achievements
    for ((id, _) in individualAchievements.entries()) {
      if (not Utils.arrayContains<Nat>(userAchievementsList, id, Utils._natEqual)) {
        userAchievementsList := Array.append(userAchievementsList, [id]);
      };
    };

    // Assign general achievements
    for ((id, _) in achievements.entries()) {
      if (not Utils.arrayContains<Nat>(userAchievementsList, id, Utils._natEqual)) {
        userAchievementsList := Array.append(userAchievementsList, [id]);
      };
    };

    playerAchievements.put(user, userAchievementsList);
    Debug.print("[assignAchievementsToUser] User achievements after update: " # debug_show (playerAchievements.get(user)));
  };

  public shared ({ caller }) func getAchievements() : async ([(AchievementCategory, [Achievement], [IndividualAchievementProgress])]) {
    // Step 1: Assign new achievements to the user if not already assigned
    await assignAchievementsToUser(caller);

    // Step 2: Get the achievements and progress assigned to the user
    let userAchievementsList : [Nat] = switch (playerAchievements.get(caller)) {
      case (null) { [] };
      case (?achievements) { achievements };
    };

    Debug.print("[getAchievements] User's assigned achievements: " # debug_show (userAchievementsList));

    let achievementsWithDetails = Buffer.Buffer<(AchievementCategory, [Achievement], [IndividualAchievementProgress])>(userAchievementsList.size());

    // Get individual achievement progress
    var userProgress : [AchievementProgress] = switch (achievementProgress.get(caller)) {
      case (null) { [] };
      case (?progress) { progress };
    };

    Debug.print("[getAchievements] User's progress: " # debug_show (userProgress));

    // Collect achievements in each category
    for (category in categories.vals()) {
      let achievementsList = Buffer.Buffer<Achievement>(category.achievements.size());
      let individualAchievementProgressList = Buffer.Buffer<IndividualAchievementProgress>(category.achievements.size());

      for (achId in category.achievements.vals()) {
        if (Utils.arrayContains<Nat>(userAchievementsList, achId, Utils._natEqual)) {
          let achievementOpt = achievements.get(achId);
          switch (achievementOpt) {
            case (null) {};
            case (?achievement) {
              achievementsList.add(achievement);

              for (indAchId in achievement.individualAchievements.vals()) {
                let indAchOpt = individualAchievements.get(indAchId);
                switch (indAchOpt) {
                  case (null) {};
                  case (?indAch) {
                    let progressOpt = Array.find<AchievementProgress>(userProgress, func(p) { p.achievementId == indAchId });
                    let indAchProgress : TypesAchievements.IndividualAchievementProgress = switch (progressOpt) {
                      case (null) {
                        {
                          individualAchievement = indAch;
                          progress = 0;
                          completed = false;
                        };
                      };
                      case (?progress) {
                        {
                          individualAchievement = indAch;
                          progress = progress.progress;
                          completed = progress.completed;
                        };
                      };
                    };
                    individualAchievementProgressList.add(indAchProgress);
                  };
                };
              };
            };
          };
        };
      };

      if (achievementsList.size() > 0) {
        achievementsWithDetails.add((category, Buffer.toArray(achievementsList), Buffer.toArray(individualAchievementProgressList)));
      };
    };

    Debug.print("[getAchievements] Achievements with details: " # debug_show (Buffer.toArray(achievementsWithDetails)));

    return Buffer.toArray(achievementsWithDetails);
  };

  // Public function to update and get achievements
  public shared ({ caller }) func updateAndGetAchievements() : async ([(AchievementCategory, [Achievement], [IndividualAchievementProgress])]) {
    await assignAchievementsToUser(caller);
    return await getAchievements();
  };

  public shared (msg) func claimAchievementReward(achievementId : Nat) : async (Bool, Text) {
    let achievementOpt = achievements.get(achievementId);
    switch (achievementOpt) {
      case (null) {
        return (false, "Achievement not found");
      };
      case (?achievement) {
        let userProgress = achievementProgress.get(msg.caller);
        switch (userProgress) {
          case (null) {
            return (false, "Achievement progress not found");
          };
          case (?progressList) {
            let progressOpt = Array.find<AchievementProgress>(progressList, func(p) { p.achievementId == achievementId });
            switch (progressOpt) {
              case (null) {
                return (false, "Achievement progress not found");
              };
              case (?progress) {
                if (not progress.completed) {
                  return (false, "Achievement not completed");
                };

                // Check if the reward has already been claimed
                let claimedRewards = switch (claimedAchievementRewards.get(msg.caller)) {
                  case (null) { [] };
                  case (?rewards) { rewards };
                };

                if (Array.find<Nat>(claimedRewards, func(r) { r == achievementId }) != null) {
                  return (false, "Achievement reward already claimed");
                };

                // Mint the rewards
                for (reward in achievement.reward.vals()) {
                  let (success, message) = await mintAchievementRewards(reward, msg.caller);
                  if (not success) {
                    return (false, message);
                  };
                };

                // Add to claimed rewards
                claimedAchievementRewards.put(msg.caller, Array.append(claimedRewards, [achievementId]));

                return (true, "Rewards claimed successfully");
              };
            };
          };
        };
      };
    };
  };

  func mintAchievementRewards(reward : TypesAchievements.AchievementReward, caller : TypesAchievements.PlayerId) : async (Bool, Text) {
    switch (reward.rewardType) {
      case (#Shards) {
        let result = await mintShards(caller, reward.amount);
        return result;
      };
      case (#Chest) {
        let result = await mintChest(caller, reward.amount);
        return result;
      };
      case (#Flux) {
        let result = await mintFlux(caller, reward.amount);
        return result;
      };
      case (#CosmicPower) {
        let result = await mintCosmicPower(caller, reward.amount);
        return result;
      };
    };
  };

  // Minting functions for specific rewards (to be implemented)
  func mintShards(_caller : PlayerId, _amount : Nat) : async (Bool, Text) {
    // Implementation for minting shards
    return (true, "Shards minted successfully");
  };

  func _mintItem(_caller : PlayerId, _items : [Text]) : async (Bool, Text) {
    // Implementation for minting items
    return (true, "Item minted successfully");
  };

  func _mintTitle(_caller : PlayerId, _title : Text) : async (Bool, Text) {
    // Implementation for minting title
    return (true, "Title minted successfully");
  };

  func _mintAvatar(_caller : PlayerId, _items : [Text]) : async (Bool, Text) {
    // Implementation for minting avatar
    return (true, "Avatar minted successfully");
  };

  func mintFlux(_caller : PlayerId, _amount : Nat) : async (Bool, Text) {
    // Implementation for minting flux
    return (true, "Flux minted successfully");
  };

  func _mintNFT(_caller : PlayerId, _items : [Text]) : async (Bool, Text) {
    // Implementation for minting NFT
    return (true, "NFT minted successfully");
  };

  func mintCosmicPower(_caller : PlayerId, _amount : Nat) : async (Bool, Text) {
    // Implementation for minting cosmic power
    return (true, "Cosmic power minted successfully");
  };

  func mapPlayerStatsToAchievementProgress(
    user : Principal,
    playerStats : {
      secRemaining : Nat;
      energyGenerated : Nat;
      damageDealt : Nat;
      damageTaken : Nat;
      energyUsed : Nat;
      deploys : Nat;
      faction : Nat;
      gameMode : Nat;
      xpEarned : Nat;
      kills : Nat;
      wonGame : Bool;
    },
  ) : [AchievementProgress] {
    var achievementProgress : [AchievementProgress] = [
      { achievementId = 0; playerId = user; progress = 1; completed = false }, // GamesCompleted
      {
        achievementId = 1;
        playerId = user;
        progress = playerStats.damageDealt;
        completed = false;
      }, // DamageDealt
      {
        achievementId = 2;
        playerId = user;
        progress = playerStats.damageTaken;
        completed = false;
      }, // DamageTaken
      {
        achievementId = 3;
        playerId = user;
        progress = playerStats.energyUsed;
        completed = false;
      }, // EnergyUsed
      {
        achievementId = 4;
        playerId = user;
        progress = playerStats.deploys;
        completed = false;
      }, // UnitsDeployed
      {
        achievementId = 5;
        playerId = user;
        progress = playerStats.faction;
        completed = false;
      }, // FactionPlayed
      {
        achievementId = 6;
        playerId = user;
        progress = playerStats.gameMode;
        completed = false;
      }, // GameModePlayed
      {
        achievementId = 7;
        playerId = user;
        progress = playerStats.xpEarned;
        completed = false;
      }, // XPEarned
      {
        achievementId = 8;
        playerId = user;
        progress = playerStats.kills;
        completed = false;
      }, // Kills
    ];

    if (playerStats.wonGame) {
      achievementProgress := Array.append(achievementProgress, [{ achievementId = 9; playerId = user; progress = 1; completed = false }]); // GamesWon
    };

    return achievementProgress;
  };

  //--
  // Progress Manager

  func updateAchievementProgressManager(
    user : Principal,
    playerStats : {
      secRemaining : Nat;
      energyGenerated : Nat;
      damageDealt : Nat;
      damageTaken : Nat;
      energyUsed : Nat;
      deploys : Nat;
      faction : Nat;
      gameMode : Nat;
      xpEarned : Nat;
      kills : Nat;
      wonGame : Bool;
      // Add other criteria like tokens minted, friends added, etc. here
    },
  ) : async (Bool, Text) {

    var achievementProgressList = mapPlayerStatsToAchievementProgress(user, playerStats);

    // Add progress from other sources (tokens minted, friends added, etc.)
    // Example:
    // achievementProgressList := Array.append(achievementProgressList, [{ achievementId = 10; playerId = user; progress = tokensMinted; completed = false }]);

    let (result, message) = await updateIndividualAchievementProgress(user, achievementProgressList);

    return (result, message);
  };

  func updateProgressManager(
    user : Principal,
    playerStats : {
      secRemaining : Nat;
      energyGenerated : Nat;
      damageDealt : Nat;
      damageTaken : Nat;
      energyUsed : Nat;
      deploys : Nat;
      faction : Nat;
      gameMode : Nat;
      xpEarned : Nat;
      kills : Nat;
      wonGame : Bool;
    },
  ) : async (Bool, Text) {

    var generalProgress : [MissionProgress] = [
      { missionType = #GamesCompleted; progress = 1 },
      { missionType = #DamageDealt; progress = playerStats.damageDealt },
      { missionType = #DamageTaken; progress = playerStats.damageTaken },
      { missionType = #EnergyUsed; progress = playerStats.energyUsed },
      { missionType = #UnitsDeployed; progress = playerStats.deploys },
      { missionType = #FactionPlayed; progress = playerStats.faction },
      { missionType = #GameModePlayed; progress = playerStats.gameMode },
      { missionType = #XPEarned; progress = playerStats.xpEarned },
      { missionType = #Kills; progress = playerStats.kills },
    ];

    if (playerStats.wonGame) {
      generalProgress := Array.append(generalProgress, [{ missionType = #GamesWon; progress = 1 }]);
    };

    let (result1, message1) = await updateGeneralMissionProgress(user, generalProgress);
    let (result2, message2) = await updateUserMissionsProgress(user, playerStats);
    let (result3, message3) = await updateAchievementProgressManager(user, playerStats);

    let success = result1 and result2 and result3;
    let message = message1 # " | " # message2 # " | " # message3;

    return (success, message);
  };

  public shared (msg) func saveFinishedGame(
    matchID : MatchID,
    _playerStats : {
      secRemaining : Nat;
      energyGenerated : Nat;
      damageDealt : Nat;
      wonGame : Bool;
      botMode : Nat;
      deploys : Nat;
      damageTaken : Nat;
      damageCritic : Nat;
      damageEvaded : Nat;
      energyChargeRate : Nat;
      faction : Nat;
      energyUsed : Nat;
      gameMode : Nat;
      energyWasted : Nat;
      xpEarned : Nat;
      characterID : Nat;
      botDifficulty : Nat;
      kills : Nat;
    },
  ) : async (Bool, Text) {
    var _txt : Text = "";

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

    Debug.print("[saveFinishedGame] Player stats: " # debug_show (playerStats));

    let isExistingMatch = switch (basicStats.get(matchID)) {
      case (null) { false };
      case (?_) { true };
    };

    let endingGame : (Bool, Bool, ?Principal) = await setGameOver(msg.caller);
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
      let newBasicStats : BasicStats = {
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
      let _elo : Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);

      Debug.print("[saveFinishedGame] Calling updateProgressManager...");
      let (success, message) = await updateProgressManager(msg.caller, playerStats);
      Debug.print("[saveFinishedGame] updateProgressManager result: " # debug_show (success) # ", message: " # message);

      if (not success) {
        return (false, "Failed to update progress: " # message);
      };

      updatePlayerGameStats(msg.caller, playerStats, _winner, _looser);
      updateOverallStats(matchID, playerStats);

      let playerOpt = players.get(msg.caller);
      switch (playerOpt) {
        case (?player) {
          let updatedPlayer : Player = {
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
          let updatedBasicStats : BasicStats = {
            playerStats = updatedPlayerStats;
          };
          basicStats.put(matchID, updatedBasicStats);

          let (_gameValid, validationMsg) = Validator.validateGame(300 - playerStats.secRemaining, playerStats.xpEarned);
          if (not _gameValid) {
            onValidation.put(matchID, updatedBasicStats);
            return (false, validationMsg);
          };

          let _winner = if (playerStats.wonGame) 1 else 0;
          let _looser = if (not playerStats.wonGame) 1 else 0;
          let _elo : Bool = await updatePlayerELO(msg.caller, _winner, endingGame.2);

          Debug.print("[saveFinishedGame] Calling updateProgressManager...");
          let (success, message) = await updateProgressManager(msg.caller, playerStats);
          Debug.print("[saveFinishedGame] updateProgressManager result: " # debug_show (success) # ", message: " # message);

          if (not success) {
            return (false, "Failed to update progress: " # message);
          };

          updatePlayerGameStats(msg.caller, playerStats, _winner, _looser);
          updateOverallStats(matchID, playerStats);

          let playerOpt = players.get(msg.caller);
          switch (playerOpt) {
            case (?player) {
              let updatedPlayer : Player = {
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

  //--
  // Players
  var ONE_SECOND : Nat64 = 1_000_000_000;
  var ONE_MINUTE : Nat64 = 60 * ONE_SECOND;

  stable var _players : [(PlayerId, Player)] = [];
  stable var _friendRequests : [(PlayerId, [FriendRequest])] = [];
  stable var _privacySettings : [(PlayerId, PrivacySetting)] = [];
  stable var _blockedUsers : [(PlayerId, [PlayerId])] = [];
  stable var _mutualFriendships : [((PlayerId, PlayerId), MutualFriendship)] = [];
  stable var _notifications : [(PlayerId, [Notification])] = [];
  stable var _updateTimestamps : [(PlayerId, UpdateTimestamps)] = [];

  // Initialize HashMaps using the stable lists
  var players : HashMap.HashMap<PlayerId, Player> = HashMap.fromIter(_players.vals(), 0, Principal.equal, Principal.hash);
  var friendRequests : HashMap.HashMap<PlayerId, [FriendRequest]> = HashMap.fromIter(_friendRequests.vals(), 0, Principal.equal, Principal.hash);
  var privacySettings : HashMap.HashMap<PlayerId, PrivacySetting> = HashMap.fromIter(_privacySettings.vals(), 0, Principal.equal, Principal.hash);
  var blockedUsers : HashMap.HashMap<PlayerId, [PlayerId]> = HashMap.fromIter(_blockedUsers.vals(), 0, Principal.equal, Principal.hash);
  var mutualFriendships : HashMap.HashMap<(PlayerId, PlayerId), MutualFriendship> = HashMap.fromIter(_mutualFriendships.vals(), 0, Utils.tupleEqual, Utils.tupleHash);
  var notifications : HashMap.HashMap<PlayerId, [Notification]> = HashMap.fromIter(_notifications.vals(), 0, Principal.equal, Principal.hash);
  var updateTimestamps : HashMap.HashMap<PlayerId, UpdateTimestamps> = HashMap.fromIter(_updateTimestamps.vals(), 0, Principal.equal, Principal.hash);

  private func addNotification(to : PlayerId, notification : Notification) {
    var userNotifications = Utils.nullishCoalescing<[Notification]>(notifications.get(to), []);
    userNotifications := Array.append(userNotifications, [notification]);
    notifications.put(to, userNotifications);
  };

  private func getDefaultTimestamps() : UpdateTimestamps {
    return {
      username = 0;
      avatar = 0;
      description = 0;
    };
  };

  private func cleanOldNotifications(playerId : PlayerId) {
    let currentTime = Time.now();
    var userNotifications = Utils.nullishCoalescing<[Notification]>(notifications.get(playerId), []);
    userNotifications := Array.filter(
      userNotifications,
      func(notification : Notification) : Bool {
        (currentTime - notification.timestamp) < 30 * 24 * 60 * 60 * 1000000000; // 30 days in nanoseconds
      },
    );
    notifications.put(playerId, userNotifications);
  };

  private func sendNotification(to : PlayerId, message : Text) {
    let notification : Notification = {
      from = to;
      message = message;
      timestamp = Time.now();
    };

    var userNotifications = Utils.nullishCoalescing<[Notification]>(notifications.get(to), []);
    if (
      Array.find(
        userNotifications,
        func(n : Notification) : Bool {
          n.message == message and Nat64.fromIntWrap(Time.now() - n.timestamp) < ONE_MINUTE;
        },
      ) == null
    ) {
      addNotification(to, notification);
    };
    cleanOldNotifications(to); // Clean old notifications after adding a new one
  };

  public shared ({ caller : PlayerId }) func registerPlayer(username : Username, avatar : AvatarID) : async (Bool, ?Player, Text) {
    if (username.size() > 12) {
      return (false, null, "Username must be 12 characters or less");
    };

    let playerId = caller;

    // Check if the player is already registered
    switch (players.get(playerId)) {
      case (?_) {
        return (false, null, "User is already registered");
      };
      case (null) {
        let registrationDate = Time.now();
        let newPlayer : Player = {
          id = playerId;
          username = username;
          avatar = avatar;
          description = "";
          registrationDate = registrationDate;
          level = 1;
          elo = 1200;
          friends = [];
        };
        players.put(playerId, newPlayer);

        // Call getAchievements function asynchronously without waiting for its result
        ignore await getAchievements();

        return (true, ?newPlayer, "User registered successfully");
      };
    };
  };

  public shared ({ caller : PlayerId }) func updateUsername(username : Username) : async (Bool, PlayerId, Text) {
    let playerId = caller;
    let currentTime = Nat64.fromIntWrap(Time.now());

    switch (players.get(playerId)) {
      case (null) {
        return (false, playerId, "User record does not exist");
      };
      case (?player) {
        if (player.username == username) {
          return (false, playerId, "New username cannot be the same as the current username");
        };

        let timestamps = Utils.nullishCoalescing<UpdateTimestamps>(updateTimestamps.get(playerId), getDefaultTimestamps());
        let usernameTimestamp = timestamps.username;

        if (Nat64.sub(currentTime, usernameTimestamp) < ONE_MINUTE) {
          return (false, playerId, "You can only update your username once every minute");
        };

        let updatedPlayer : Player = {
          id = player.id;
          username = username;
          avatar = player.avatar;
          description = player.description;
          registrationDate = player.registrationDate;
          level = player.level;
          elo = player.elo;
          friends = player.friends;
        };
        players.put(playerId, updatedPlayer);

        let updatedTimestamps = { timestamps with username = currentTime };
        updateTimestamps.put(playerId, updatedTimestamps);

        return (true, playerId, "Username updated successfully");
      };
    };
  };

  public shared ({ caller : PlayerId }) func updateAvatar(avatar : AvatarID) : async (Bool, PlayerId, Text) {
    let playerId = caller;
    let currentTime = Nat64.fromIntWrap(Time.now());

    switch (players.get(playerId)) {
      case (null) {
        return (false, playerId, "User record does not exist");
      };
      case (?player) {
        if (player.avatar == avatar) {
          return (false, playerId, "New avatar cannot be the same as the current avatar");
        };

        let timestamps = Utils.nullishCoalescing<UpdateTimestamps>(updateTimestamps.get(playerId), getDefaultTimestamps());
        let avatarTimestamp = timestamps.avatar;

        if (Nat64.sub(currentTime, avatarTimestamp) < ONE_MINUTE) {
          return (false, playerId, "You can only update your avatar once every minute");
        };

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
        players.put(playerId, updatedPlayer);

        let updatedTimestamps = { timestamps with avatar = currentTime };
        updateTimestamps.put(playerId, updatedTimestamps);

        return (true, playerId, "Avatar updated successfully");
      };
    };
  };

  public shared ({ caller : PlayerId }) func updateDescription(description : Description) : async (Bool, PlayerId, Text) {
    let playerId = caller;
    let currentTime = Nat64.fromIntWrap(Time.now());

    if (description.size() > 160) {
      return (false, playerId, "Description must be 160 characters or less");
    };

    switch (players.get(playerId)) {
      case (null) {
        return (false, playerId, "User record does not exist");
      };
      case (?player) {
        if (player.description == description) {
          return (false, playerId, "New description cannot be the same as the current description");
        };

        let timestamps = Utils.nullishCoalescing<UpdateTimestamps>(updateTimestamps.get(playerId), getDefaultTimestamps());
        let descriptionTimestamp = timestamps.description;

        if (Nat64.sub(currentTime, descriptionTimestamp) < ONE_MINUTE) {
          return (false, playerId, "You can only update your description once every minute");
        };

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
        players.put(playerId, updatedPlayer);

        let updatedTimestamps = { timestamps with description = currentTime };
        updateTimestamps.put(playerId, updatedTimestamps);

        return (true, playerId, "Description updated successfully");
      };
    };
  };

  public shared ({ caller : PlayerId }) func sendFriendRequest(friendId : PlayerId) : async (Bool, Text) {
    let playerId = caller;

    // Prevent sending friend request to self
    if (playerId == friendId) {
      return (false, "Cannot send friend request to yourself");
    };

    // Check if the player is blocked by the recipient
    if (isBlockedBy(friendId, playerId)) {
      return (false, "You are blocked by this user");
    };

    // Check if the players are already friends
    if (areFriends(playerId, friendId)) {
      return (false, "You are already friends with this user");
    };

    switch (players.get(playerId)) {
      case (null) {
        return (false, "User record does not exist");
      };
      case (?player) {
        switch (players.get(friendId)) {
          case (null) {
            return (false, "Friend principal not registered");
          };
          case (?_) {
            if (not canSendRequestToNonFriend(playerId, friendId)) {
              return (false, "Cannot send friend request to this user");
            };

            var requests = Utils.nullishCoalescing<[FriendRequest]>(friendRequests.get(friendId), []);
            if (findFriendRequestIndex(requests, playerId) != null) {
              return (false, "Friend request already sent");
            };

            let newRequest : FriendRequest = {
              from = playerId;
              to = friendId;
              timestamp = Time.now();
            };

            requests := Array.append<FriendRequest>(requests, [newRequest]);
            friendRequests.put(friendId, requests);

            sendNotification(friendId, "You have a new friend request from " # player.username);

            return (true, "Friend request sent successfully");
          };
        };
      };
    };
  };

  public shared ({ caller : PlayerId }) func acceptFriendRequest(fromId : PlayerId) : async (Bool, Text) {
    let playerId = caller;
    switch (players.get(playerId)) {
      case (null) {
        return (false, "User record does not exist");
      };
      case (?_player) {
        var requests = Utils.nullishCoalescing<[FriendRequest]>(friendRequests.get(playerId), []);
        let requestIndex = findFriendRequestIndex(requests, fromId);
        switch (requestIndex) {
          case (null) {
            return (false, "Friend request not found");
          };
          case (?_index) {
            // Remove the request from the list
            requests := Array.filter<FriendRequest>(requests, func(req : FriendRequest) : Bool { req.from != fromId });
            friendRequests.put(playerId, requests);

            // Add friend to both users' friends list
            addFriendToUser(playerId, fromId);
            addFriendToUser(fromId, playerId);

            // Record the mutual friendship with timestamp
            let friendship : MutualFriendship = {
              friend1 = playerId;
              friend2 = fromId;
              friendsSince = Time.now();
            };
            mutualFriendships.put((playerId, fromId), friendship);
            mutualFriendships.put((fromId, playerId), friendship);

            return (true, "Friend request accepted");
          };
        };
      };
    };
  };

  public shared ({ caller : PlayerId }) func declineFriendRequest(fromId : PlayerId) : async (Bool, Text) {
    let playerId = caller;
    switch (players.get(playerId)) {
      case (null) {
        return (false, "User record does not exist");
      };
      case (?_) {
        var requests = Utils.nullishCoalescing<[FriendRequest]>(friendRequests.get(playerId), []);
        let requestIndex = findFriendRequestIndex(requests, fromId);
        switch (requestIndex) {
          case (null) {
            return (false, "Friend request not found");
          };
          case (?_index) {
            // Remove the request from the list
            requests := Array.filter<FriendRequest>(requests, func(req : FriendRequest) : Bool { req.from != fromId });
            friendRequests.put(playerId, requests);
            return (true, "Friend request declined");
          };
        };
      };
    };
  };

  public shared ({ caller : PlayerId }) func blockUser(blockedId : PlayerId) : async (Bool, Text) {
    let playerId = caller;

    // Prevent blocking oneself
    if (playerId == blockedId) {
      return (false, "Cannot block yourself");
    };

    switch (players.get(playerId)) {
      case (null) {
        return (false, "User record does not exist");
      };
      case (?_player) {
        var blockedUsersList = Utils.nullishCoalescing<[PlayerId]>(blockedUsers.get(playerId), []);

        // Prevent blocking the same user more than once
        if (isUserBlocked(blockedUsersList, blockedId)) {
          return (false, "User is already blocked");
        };

        blockedUsersList := Array.append(blockedUsersList, [blockedId]);
        blockedUsers.put(playerId, blockedUsersList);

        // Remove friend request from blocked user if it exists
        var requests = Utils.nullishCoalescing<[FriendRequest]>(friendRequests.get(playerId), []);
        let requestIndex = findFriendRequestIndex(requests, blockedId);
        switch (requestIndex) {
          case (null) {};
          case (?_index) {
            requests := Array.filter<FriendRequest>(requests, func(req : FriendRequest) : Bool { req.from != blockedId });
            friendRequests.put(playerId, requests);
          };
        };

        return (true, "User blocked successfully");
      };
    };
  };

  public shared ({ caller : PlayerId }) func unblockUser(blockedId : PlayerId) : async (Bool, Text) {
    let playerId = caller;
    switch (players.get(playerId)) {
      case (null) {
        return (false, "User record does not exist");
      };
      case (?_player) {
        var blockedUsersList = Utils.nullishCoalescing<[PlayerId]>(blockedUsers.get(playerId), []);
        blockedUsersList := Array.filter(blockedUsersList, func(blocked : PlayerId) : Bool { blocked != blockedId });
        blockedUsers.put(playerId, blockedUsersList);
        return (true, "User unblocked successfully");
      };
    };
  };

  public shared ({ caller : PlayerId }) func setPrivacySetting(setting : PrivacySetting) : async (Bool, Text) {
    let playerId = caller;
    switch (players.get(playerId)) {
      case (null) {
        return (false, "User record does not exist");
      };
      case (?_player) {
        let currentSetting = Utils.nullishCoalescing<PrivacySetting>(privacySettings.get(playerId), #acceptAll);
        if (currentSetting != setting) {
          privacySettings.put(playerId, setting);
          sendNotification(playerId, "Your privacy settings have been updated.");
        };
        return (true, "Privacy settings updated successfully");
      };
    };
  };

  public query ({ caller : PlayerId }) func getBlockedUsers() : async [PlayerId] {
    return Utils.nullishCoalescing<[PlayerId]>(blockedUsers.get(caller), []);
  };

  private func addFriendToUser(userId : PlayerId, friendId : PlayerId) {
    switch (players.get(userId)) {
      case (null) {};
      case (?user) {
        switch (players.get(friendId)) {
          case (null) {};
          case (?friend) {
            // Ensure friend is not already in user's friends list
            if (Array.find(user.friends, func(f : FriendDetails) : Bool { f.playerId == friendId }) == null) {
              let updatedUserFriends = Array.append(user.friends, [{ playerId = friendId; username = friend.username; avatar = friend.avatar }]);
              players.put(userId, { user with friends = updatedUserFriends });
            };

            // Ensure user is not already in friend's friends list
            if (Array.find(friend.friends, func(f : FriendDetails) : Bool { f.playerId == userId }) == null) {
              let updatedFriendFriends = Array.append(friend.friends, [{ playerId = userId; username = user.username; avatar = user.avatar }]);
              players.put(friendId, { friend with friends = updatedFriendFriends });
            };
          };
        };
      };
    };
  };

  // Helper function to check if two players are friends
  private func areFriends(playerId1 : PlayerId, playerId2 : PlayerId) : Bool {
    switch (mutualFriendships.get((playerId1, playerId2))) {
      case (null) false;
      case (?_) true;
    };
  };

  // Helper function to check if a request can be sent from a non-friend
  private func canSendRequestToNonFriend(senderId : PlayerId, recipientId : PlayerId) : Bool {
    let privacySetting = getPrivacySettings(recipientId);
    switch (privacySetting) {
      case (#acceptAll) true;
      case (#blockAll) false;
      case (#friendsOfFriends) areFriends(senderId, recipientId);
    };
  };

  private func findFriendRequestIndex(requests : [FriendRequest], fromId : PlayerId) : ?Nat {
    for (index in Iter.range(0, Array.size(requests) - 1)) {
      if (requests[index].from == fromId) {
        return ?index;
      };
    };
    return null;
  };

  // Helper function to check if a user is in the blocked list
  private func isUserBlocked(blockedUsersList : [PlayerId], userId : PlayerId) : Bool {
    return Array.find(blockedUsersList, func(blocked : PlayerId) : Bool { blocked == userId }) != null;
  };

  private func isBlockedBy(blockedId : PlayerId, playerId : PlayerId) : Bool {
    switch (blockedUsers.get(blockedId)) {
      case (null) false;
      case (?userBlockedList) isUserBlocked(userBlockedList, playerId);
    };
  };

  private func getPrivacySettings(playerId : PlayerId) : PrivacySetting {
    Utils.nullishCoalescing<PrivacySetting>(privacySettings.get(playerId), #acceptAll);
  };

  // QPlayers

  public query ({ caller : PlayerId }) func getNotifications() : async [Notification] {
    return Utils.nullishCoalescing<[Notification]>(notifications.get(caller), []);
  };

  public query ({ caller : PlayerId }) func getFriendRequests() : async [FriendRequest] {
    return Utils.nullishCoalescing<[FriendRequest]>(friendRequests.get(caller), []);
  };

  public query ({ caller : PlayerId }) func getMyPrivacySettings() : async PrivacySetting {
    return getPrivacySettings(caller);
  };

  // Query function to self get player data
  public query (msg) func getPlayer() : async ?Player {
    return players.get(msg.caller);
  };

  // Function to get another user profile
  public query func getProfile(player : PlayerId) : async ?Player {
    return players.get(player);
  };

  // Full User Profile with statistics and friends
  public query func getFullUserProfile(player : PlayerId) : async ?(Player, PlayerGamesStats, AverageStats) {
    switch (players.get(player)) {
      case (null) { return null };
      case (?playerData) {
        let playerStatsOpt = playerGamesStats.get(player);
        let playerStats = switch (playerStatsOpt) {
          case (null) {
            let initialStats : PlayerGamesStats = {
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
          case (?stats) { stats };
        };

        let gamesPlayed = playerStats.gamesPlayed;
        let averageStats : AverageStats = {
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
  public query ({ caller : PlayerId }) func getFriendsList() : async ?[PlayerId] {
    switch (players.get(caller)) {
      case (null) {
        return null; // User record does not exist
      };
      case (?player) {
        let friendIds = Array.map<FriendDetails, PlayerId>(
          player.friends,
          func(friend : FriendDetails) : PlayerId {
            return friend.playerId;
          },
        );
        return ?friendIds;
      };
    };
  };

  // List all players
  public query func getAllPlayers() : async [Player] {
    return Iter.toArray(players.vals());
  };

  //--
  // Statistics

  // Nulls or Anons cannot use matchmaking (later add non registered players and Level req. + loss default inactivity)
  let NULL_PRINCIPAL : Principal = Principal.fromText("aaaaa-aa");
  let ANON_PRINCIPAL : Principal = Principal.fromText("2vxsx-fae");

  stable var _basicStats : [(MatchID, BasicStats)] = [];
  var basicStats : HashMap.HashMap<MatchID, BasicStats> = HashMap.fromIter(_basicStats.vals(), 0, Utils._natEqual, Utils._natHash);

  stable var _playerGamesStats : [(PlayerId, PlayerGamesStats)] = [];
  var playerGamesStats : HashMap.HashMap<PlayerId, PlayerGamesStats> = HashMap.fromIter(_playerGamesStats.vals(), 0, Principal.equal, Principal.hash);

  stable var _onValidation : [(MatchID, BasicStats)] = [];
  var onValidation : HashMap.HashMap<MatchID, BasicStats> = HashMap.fromIter(_onValidation.vals(), 0, Utils._natEqual, Utils._natHash);

  stable var _countedMatches : [(MatchID, Bool)] = [];
  var countedMatches : HashMap.HashMap<MatchID, Bool> = HashMap.fromIter(_countedMatches.vals(), 0, Utils._natEqual, Utils._natHash);

  stable var overallStats : OverallStats = {
    totalGamesPlayed : Nat = 0;
    totalGamesSP : Nat = 0;
    totalGamesMP : Nat = 0;
    totalDamageDealt : Nat = 0;
    totalTimePlayed : Nat = 0;
    totalKills : Nat = 0;
    totalEnergyGenerated : Nat = 0;
    totalEnergyUsed : Nat = 0;
    totalEnergyWasted : Nat = 0;
    totalXpEarned : Nat = 0;
    totalGamesWithFaction : [GamesWithFaction] = [];
    totalGamesGameMode : [GamesWithGameMode] = [];
    totalGamesWithCharacter : [GamesWithCharacter] = [];
  };

  func _initializeNewPlayerStats(_player : Principal) : async (Bool, Text) {
    let _playerStats : PlayerGamesStats = {
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

  func setGameOver(caller : Principal) : async (Bool, Bool, ?Principal) {
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
        let winFactor : Float = if (_p1Elo < 1400.0) 2.0 else if (_p1Elo < 1800.0) 1.75 else if (_p1Elo < 2200.0) 1.5 else if (_p1Elo < 2600.0) 1.25 else 1.0;

        let lossFactor : Float = if (_p1Elo < 1400.0) 0.1 else if (_p1Elo < 1800.0) 0.5 else if (_p1Elo < 2200.0) 1.0 else if (_p1Elo < 2600.0) 1.25 else 2.0;

        // Calculate expected win probability
        let _p1Expected : Float = 1 / (1 + Float.pow(10, (_p2Elo - _p1Elo) / 400));
        let _p2Expected : Float = 1 / (1 + Float.pow(10, (_p1Elo - _p2Elo) / 400));

        // Calculate ELO change
        let pointChange : Float = if (won == 1) baseKFactor * winFactor * (1 - _p1Expected) else -baseKFactor * lossFactor * _p1Expected;

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
  func isCallerPartOfMatch(matchID : MatchID, caller : Principal) : async Bool {
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
    };
  };

  // Function to update player stats
  func updatePlayerGameStats(playerId : PlayerId, _playerStats : PlayerStats, _winner : Nat, _looser : Nat) {
    switch (playerGamesStats.get(playerId)) {
      case (null) {
        let _gs : PlayerGamesStats = {
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
          totalGamesWithFaction = [{
            factionID = _playerStats.faction;
            gamesPlayed = 1;
            gamesWon = _winner;
          }];
          totalGamesGameMode = [{
            gameModeID = _playerStats.gameMode;
            gamesPlayed = 1;
            gamesWon = _winner;
          }];
          totalGamesWithCharacter = [{
            characterID = _playerStats.characterID;
            gamesPlayed = 1;
            gamesWon = _winner;
          }];
        };
        playerGamesStats.put(playerId, _gs);
      };
      case (?_bs) {
        let _gamesWithFactionBuffer = Buffer.Buffer<GamesWithFaction>(_bs.totalGamesWithFaction.size());
        for (gf in _bs.totalGamesWithFaction.vals()) {
          if (gf.factionID == _playerStats.faction) {
            _gamesWithFactionBuffer.add({
              gamesPlayed = gf.gamesPlayed + 1;
              factionID = gf.factionID;
              gamesWon = gf.gamesWon + _winner;
            });
          } else {
            _gamesWithFactionBuffer.add(gf);
          };
        };
        let _gamesWithFaction = Buffer.toArray(_gamesWithFactionBuffer);

        let _gamesWithGameModeBuffer = Buffer.Buffer<GamesWithGameMode>(_bs.totalGamesGameMode.size());
        for (gm in _bs.totalGamesGameMode.vals()) {
          if (gm.gameModeID == _playerStats.gameMode) {
            _gamesWithGameModeBuffer.add({
              gamesPlayed = gm.gamesPlayed + 1;
              gameModeID = gm.gameModeID;
              gamesWon = gm.gamesWon + _winner;
            });
          } else {
            _gamesWithGameModeBuffer.add(gm);
          };
        };
        let _gamesWithGameMode = Buffer.toArray(_gamesWithGameModeBuffer);

        let _totalGamesWithCharacterBuffer = Buffer.Buffer<GamesWithCharacter>(_bs.totalGamesWithCharacter.size());
        for (gc in _bs.totalGamesWithCharacter.vals()) {
          if (gc.characterID == _playerStats.characterID) {
            _totalGamesWithCharacterBuffer.add({
              gamesPlayed = gc.gamesPlayed + 1;
              characterID = gc.characterID;
              gamesWon = gc.gamesWon + _winner;
            });
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

        let _gs : PlayerGamesStats = {
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
  func updateOverallStats(matchID : MatchID, _playerStats : PlayerStats) {
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

    let maxGameTime : Nat = 300; // 5 minutes in seconds
    let timePlayed : Nat = maxGameTime - _playerStats.secRemaining;

    let _os : OverallStats = {
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

  public shared query (msg) func getMyStats() : async ?PlayerGamesStats {
    switch (playerGamesStats.get(msg.caller)) {
      case (null) {
        let _playerStats : PlayerGamesStats = {
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
        return ?_playerStats;
      };
      case (?_p) {
        return playerGamesStats.get(msg.caller);
      };
    };
  };

  //--
  // MatchMaking

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

  // Function for matchmaking to get player ELO
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
  public query func getPlayerStats(player : PlayerId) : async ?PlayerGamesStats {
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

  public query func getMatchParticipants(matchID : MatchID) : async ?(Principal, ?Principal) {
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
    };
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
        let _p1Name = switch (_p1Data) {
          case (null) "";
          case (?p1) p1.username;
        };
        let _p1Avatar = switch (_p1Data) { case (null) 0; case (?p1) p1.avatar };
        let _p1Level = switch (_p1Data) { case (null) 0; case (?p1) p1.level };

        let _fullPlayer2 = switch (_m.player2) {
          case null null;
          case (?p2) {
            let _p2D = await getProfile(p2.id);
            ?{
              id = p2.id;
              username = switch (_p2D) { case (null) ""; case (?p) p.username };
              avatar = switch (_p2D) { case (null) 0; case (?p) p.avatar };
              level = switch (_p2D) { case (null) 0; case (?p) p.level };
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
  public query func getMatchIDsByPrincipal(player : PlayerId) : async [MatchID] {
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
            };
          };
        };
      };
    };
    return Buffer.toArray(buffer);
  };

  // Basic Stats sent for a MatchID
  public query func getMatchStats(MatchID : MatchID) : async ?BasicStats {
    return basicStats.get(MatchID);
  };

  // Basic Stats + User Profiles for a MatchID
  public query func getMatchDetails(matchID : MatchID) : async ?(MatchData, [(Player, PlayerGamesStats)]) {
    let matchDataOpt = switch (finishedGames.get(matchID)) {
      case (null) {
        switch (inProgress.get(matchID)) {
          case (null) {
            switch (searching.get(matchID)) {
              case (null) { return null };
              case (?matchData) { ?matchData };
            };
          };
          case (?matchData) { ?matchData };
        };
      };
      case (?matchData) { ?matchData };
    };

    switch (matchDataOpt) {
      case (null) { return null };
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

  public query func getMatchHistoryByPrincipal(player : PlayerId) : async [(MatchID, ?BasicStats)] {
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
            };
          };
        };
      };
    };
    return Buffer.toArray(buffer);
  };

  public query func test(playerId : PlayerId) : async ?{
    username : Username;
    level : Level;
    elo : Float;
    xp : Nat;
    gamesWon : Nat;
    gamesLost : Nat;
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

  //--
  // Custom Matchmaking

  //--
  // ICRCs

  type Result<S, E> = Result.Result<S, E>;

  let shards : ICRC1Interface = actor ("svcoe-6iaaa-aaaam-ab4rq-cai") : ICRC1Interface;

  let flux : ICRC1Interface = actor ("plahz-wyaaa-aaaam-accta-cai") : ICRC1Interface;

  let gameNFTs : ICRC7Interface = actor ("etqmj-zyaaa-aaaap-aakaq-cai") : ICRC7Interface;

  let chests : ICRC7Interface = actor ("opcce-byaaa-aaaak-qcgda-cai") : ICRC7Interface;

  // ICRC 1
  type ICRC1Interface = actor {
    icrc1_name : shared () -> async Text;
    icrc1_symbol : shared () -> async Text;
    icrc1_decimals : shared () -> async Nat8;
    icrc1_fee : shared () -> async TypesICRC1.Balance;
    icrc1_metadata : shared () -> async [TypesICRC1.MetaDatum];
    icrc1_total_supply : shared () -> async TypesICRC1.Balance;
    icrc1_minting_account : shared () -> async ?TypesICRC1.Account;
    icrc1_balance_of : shared (args : TypesICRC1.Account) -> async TypesICRC1.Balance;
    icrc1_supported_standards : shared () -> async [TypesICRC1.SupportedStandard];
    icrc1_transfer : shared (args : TypesICRC1.TransferArgs) -> async TypesICRC1.TransferResult;
    icrc1_pay_for_transaction : shared (args : TypesICRC1.TransferArgs, from : Principal) -> async TypesICRC1.TransferResult;
    mint : shared (args : TypesICRC1.Mint) -> async TypesICRC1.TransferResult;
    burn : shared (args : TypesICRC1.BurnArgs) -> async TypesICRC1.TransferResult;
    get_transactions : shared (req : TypesICRC1.GetTransactionsRequest) -> async TypesICRC1.GetTransactionsResponse;
    get_transaction : shared (i : TypesICRC1.TxIndex) -> async ?TypesICRC1.Transaction;
    deposit_cycles : shared () -> async ();
  };

  // ICRC 7
  type ICRC7Interface = actor {
    icrc7_collection_metadata : shared () -> async TypesICRC7.CollectionMetadata;
    icrc7_name : shared () -> async Text;
    icrc7_symbol : shared () -> async Text;
    icrc7_royalties : shared () -> async ?Nat16;
    icrc7_royalty_recipient : shared () -> async ?TypesICRC7.Account;
    icrc7_description : shared () -> async ?Text;
    icrc7_image : shared () -> async ?Blob;
    icrc7_total_supply : shared () -> async Nat;
    icrc7_supply_cap : shared () -> async ?Nat;
    icrc7_metadata : shared (tokenId : TypesICRC7.TokenId) -> async TypesICRC7.MetadataResult;
    icrc7_owner_of : shared (tokenId : TypesICRC7.TokenId) -> async TypesICRC7.OwnerResult;
    icrc7_balance_of : shared (account : TypesICRC7.Account) -> async TypesICRC7.BalanceResult;
    icrc7_tokens_of : shared (account : TypesICRC7.Account) -> async TypesICRC7.TokensOfResult;
    icrc7_transfer : shared (transferArgs : TypesICRC7.TransferArgs) -> async TypesICRC7.TransferReceipt;
    icrc7_approve : shared (approvalArgs : TypesICRC7.ApprovalArgs) -> async TypesICRC7.ApprovalReceipt;
    icrc7_supported_standards : shared () -> async [TypesICRC7.SupportedStandard];
    mint : shared (mintArgs : TypesICRC7.MintArgs) -> async TypesICRC7.MintReceipt;
    upgradeNFT : shared (upgradeArgs : TypesICRC7.UpgradeArgs) -> async TypesICRC7.UpgradeReceipt;
    mintDeck : shared (deck : [TypesICRC7.MintArgs]) -> async TypesICRC7.MintReceipt;
    get_transactions : shared (getTransactionsArgs : TypesICRC7.GetTransactionsArgs) -> async TypesICRC7.GetTransactionsResult;
    openChest : shared (args : TypesICRC7.OpenArgs) -> async TypesICRC7.OpenReceipt;
    updateChestMetadata : shared (updateArgs : TypesICRC7.UpdateArgs) -> async TypesICRC7.Result<TypesICRC7.TokenId, TypesICRC7.UpdateError>;
  };

  // GameNFTs

  // Mint deck with 8 units and random rarity within a range provided
  public func mintDeck(caller : Principal) : async (Bool, Text) {
    let units = Utils.initDeck();

    var _deck = Buffer.Buffer<TypesICRC7.MintArgs>(8);
    var uuids = Buffer.Buffer<TokenID>(8);

    // Generate the initial UUID
    let initialUUID = await Utils.generateUUID64();

    for (i in Iter.range(0, 7)) {
      let (name, damage, hp, rarity) = units[i];
      // Increment the UUID for each NFT
      let uuid = initialUUID + i;
      let _mintArgs : TypesICRC7.MintArgs = {
        to = { owner = caller; subaccount = null };
        token_id = uuid;
        metadata = Utils.getBaseMetadataWithAttributes(rarity, i + 1, name, damage, hp);
      };
      _deck.add(_mintArgs);
      uuids.add(uuid); // Collect the UUIDs
    };

    let mintResult = await gameNFTs.mintDeck(Buffer.toArray(_deck));
    switch (mintResult) {
      case (#Ok(_transactionID)) {
        // Update the minted NFTs for the caller
        for (uuid in uuids.vals()) {
          await updateMintedGameNFTs(caller, uuid);
        };
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

  public shared (msg) func upgradeNFT(nftID : TokenID) : async (Bool, Text) {
    // Initiate metadata retrieval in the background
    let metadataFuture = async { await gameNFTs.icrc7_metadata(nftID) };

    // Perform ownership check
    let ownerof : TypesICRC7.OwnerResult = await gameNFTs.icrc7_owner_of(nftID);
    let _owner : TypesICRC7.Account = switch (ownerof) {
      case (#Ok(owner)) owner;
      case (#Err(_)) return (false, "{\"success\":false, \"message\":\"NFT not found\"}");
    };
    if (Principal.notEqual(_owner.owner, msg.caller)) {
      return (false, "{\"success\":false, \"message\":\"You do not own this NFT.\"}");
    };

    // Wait for metadata retrieval
    let metadataResult = await metadataFuture;
    let _nftMetadata : [(Text, TypesICRC7.Metadata)] = switch (metadataResult) {
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
  func _processUpgrade(nftID : TokenID, caller : Principal, _nftMetadata : [(Text, TypesICRC7.Metadata)]) : async () {
    // Calculate upgrade cost
    let nftLevel : Nat = Utils.getNFTLevel(_nftMetadata);
    let upgradeCost = Utils.calculateCost(nftLevel);
    let fee = await shards.icrc1_fee();

    // Create transaction arguments for the upgrade cost
    let _transactionsArgs = {
      amount : TypesICRC1.Balance = upgradeCost;
      created_at_time : ?Nat64 = ?Nat64.fromNat(Int.abs(Time.now()));
      fee = ?fee;
      from_subaccount : ?TypesICRC1.Subaccount = null;
      memo : ?Blob = null;
      to : TypesICRC1.Account = {
        owner = Principal.fromText("aaaaa-aa");
        subaccount = null;
      };
    };

    // Transfer the upgrade cost
    let transfer : TypesICRC1.TransferResult = await shards.icrc1_pay_for_transaction(_transactionsArgs, caller);

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
  func _executeUpgrade(nftID : TokenID, caller : Principal, _nftMetadata : [(Text, TypesICRC7.Metadata)]) : async () {
    // Prepare for upgrade
    let _newArgsBuffer = Buffer.Buffer<(Text, TypesICRC7.Metadata)>(_nftMetadata.size());
    let nftLevel : Nat = Utils.getNFTLevel(_nftMetadata);

    // Update metadata
    for (_md in _nftMetadata.vals()) {
      let _mdKey : Text = _md.0;
      let _mdValue : TypesICRC7.Metadata = _md.1;
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

    let _upgradeArgs : TypesICRC7.UpgradeArgs = {
      from = { owner = caller; subaccount = null };
      token_id = nftID;
      metadata = Buffer.toArray(_newArgsBuffer);
      date_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
    };
    let upgrade : TypesICRC7.UpgradeReceipt = await gameNFTs.upgradeNFT(_upgradeArgs);
    switch (upgrade) {
      case (#Ok(_)) Debug.print("[_executeUpgrade]NFT upgraded successfully.");
      case (#Err(_e)) Debug.print("[_executeUpgrade]NFT upgrade failed:");
    };
  };

  // Chests
  private func mintChest(PlayerId : Principal, rarity : Nat) : async (Bool, Text) {
    let uuid = await Utils.generateUUID64();
    let _mintArgs : TypesICRC7.MintArgs = {
      to = { owner = PlayerId; subaccount = null };
      token_id = uuid;
      metadata = Utils.getChestMetadata(rarity);
    };
    let mintResult = await chests.mint(_mintArgs);
    switch (mintResult) {
      case (#Ok(_transactionID)) {
        await updateMintedChests(PlayerId, uuid);
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

  public shared ({ caller }) func openChest(chestID : Nat) : async (Bool, Text) {
    // Perform ownership check
    let ownerof : TypesICRC7.OwnerResult = await chests.icrc7_owner_of(chestID);
    let _owner : TypesICRC7.Account = switch (ownerof) {
      case (#Ok(owner)) owner;
      case (#Err(_)) return (false, "{\"error\":true, \"message\":\"Chest not found\"}");
    };

    if (Principal.notEqual(_owner.owner, caller)) {
      return (false, "{\"error\":true, \"message\":\"Not the owner of the chest\"}");
    };

    // Get tokens to be minted and burn the chest
    let _chestArgs : TypesICRC7.OpenArgs = {
      from = _owner;
      token_id = chestID;
    };

    // Additional checks before calling openChest
    if (Principal.notEqual(_chestArgs.from.owner, caller)) {
      return (false, "{\"error\":true, \"message\":\"Unauthorized: Owner mismatch in _chestArgs\"}");
    };

    let _tokens : TypesICRC7.OpenReceipt = await chests.openChest(_chestArgs);

    var _tokensResults : Text = "";

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
        let _shardsArgs : TypesICRC1.Mint = {
          to = { owner = caller; subaccount = null };
          amount = shardsAmount;
          memo = null;
          created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };

        let _fluxArgs : TypesICRC1.Mint = {
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
          case (#Ok(_tid)) {
            await updateMintedShards(caller, shardsAmount);
            "{\"token\":\"Shards\", \"transaction_id\": " # Nat.toText(_tid) # ", \"amount\": " # Nat.toText(shardsAmount) # "}";
          };
          case (#Err(_e)) Utils.handleMintError("Shards", _e);
        };

        // Handle flux minting result
        let fluxResult = switch (fluxMinted) {
          case (#Ok(_tid)) {
            await updateMintedFlux(caller, fluxAmount);
            "{\"token\":\"Flux\", \"transaction_id\": " # Nat.toText(_tid) # ", \"amount\": " # Nat.toText(fluxAmount) # "}";
          };
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
  //--
  //Logging

  // Types
  public type MintedShards = {
    quantity : Nat;
  };

  public type MintedFlux = {
    quantity : Nat;
  };

  public type MintedChest = {
    tokenIDs : [TokenID];
    quantity : Nat;
  };

  public type MintedGameNFT = {
    tokenIDs : [TokenID];
    quantity : Nat;
  };

  type LogEntry = {
    itemType : ItemType;
    user : Principal;
    amount : ?Nat;
    tokenID : ?TokenID;
    timestamp : Nat64;
  };

  type ItemType = {
    #Shards;
    #GameNFTs;
    #Chest;
    #Flux;
  };

  // Stable variables for storing minted token information
  stable var mintedShards : [(Principal, MintedShards)] = [];
  stable var mintedFlux : [(Principal, MintedFlux)] = [];
  stable var mintedChests : [(Principal, MintedChest)] = [];
  stable var mintedGameNFTs : [(Principal, MintedGameNFT)] = [];
  stable var transactionLogs : [LogEntry] = [];

  // HashMaps for minted token information
  var mintedShardsMap : HashMap.HashMap<Principal, MintedShards> = HashMap.HashMap<Principal, MintedShards>(10, Principal.equal, Principal.hash);
  var mintedFluxMap : HashMap.HashMap<Principal, MintedFlux> = HashMap.HashMap<Principal, MintedFlux>(10, Principal.equal, Principal.hash);
  var mintedChestsMap : HashMap.HashMap<Principal, MintedChest> = HashMap.HashMap<Principal, MintedChest>(10, Principal.equal, Principal.hash);
  var mintedGameNFTsMap : HashMap.HashMap<Principal, MintedGameNFT> = HashMap.HashMap<Principal, MintedGameNFT>(10, Principal.equal, Principal.hash);

  //Functions
  // Function to update stable variables
  func updateStableVariables() {
    mintedShards := Iter.toArray(mintedShardsMap.entries());
    mintedFlux := Iter.toArray(mintedFluxMap.entries());
    mintedChests := Iter.toArray(mintedChestsMap.entries());
    mintedGameNFTs := Iter.toArray(mintedGameNFTsMap.entries());
  };

  // Function to update minted shards
  func updateMintedShards(user : Principal, amount : Nat) : async () {
    let current = switch (mintedShardsMap.get(user)) {
      case (null) { { quantity = 0 } };
      case (?shards) { shards };
    };
    let updated = { quantity = current.quantity + amount };
    mintedShardsMap.put(user, updated);
    let timestamp : Nat64 = Nat64.fromIntWrap(Time.now());
    logTransaction(#Shards, user, amount, timestamp);
    updateStableVariables();
  };

  // Function to update minted flux
  func updateMintedFlux(user : Principal, amount : Nat) : async () {
    let current = switch (mintedFluxMap.get(user)) {
      case (null) { { quantity = 0 } };
      case (?flux) { flux };
    };
    let updated = { quantity = current.quantity + amount };
    mintedFluxMap.put(user, updated);
    let timestamp : Nat64 = Nat64.fromIntWrap(Time.now());
    logTransaction(#Flux, user, amount, timestamp);
    updateStableVariables();
  };

  // Function to update minted chests
  func updateMintedChests(user : Principal, tokenID : TokenID) : async () {
    let current = switch (mintedChestsMap.get(user)) {
      case (null) { { tokenIDs = []; quantity = 0 } };
      case (?chests) { chests };
    };
    let updated = {
      tokenIDs = Array.append(current.tokenIDs, [tokenID]);
      quantity = current.quantity + 1;
    };
    mintedChestsMap.put(user, updated);
    let timestamp : Nat64 = Nat64.fromIntWrap(Time.now());
    logTransactionWithTokenID(#Chest, user, tokenID, timestamp);
    updateStableVariables();
  };

  // Function to update minted gameNFTs
  func updateMintedGameNFTs(user : Principal, tokenID : TokenID) : async () {
    let current = switch (mintedGameNFTsMap.get(user)) {
      case (null) { { tokenIDs = []; quantity = 0 } };
      case (?nfts) { nfts };
    };
    let updated = {
      tokenIDs = Array.append(current.tokenIDs, [tokenID]);
      quantity = current.quantity + 1;
    };
    mintedGameNFTsMap.put(user, updated);
    let timestamp : Nat64 = Nat64.fromIntWrap(Time.now());
    logTransactionWithTokenID(#GameNFTs, user, tokenID, timestamp);
    updateStableVariables();
  };

  // Function to add a log entry
  func addLogEntry(itemType : ItemType, user : Principal, amount : ?Nat, tokenID : ?TokenID, timestamp : Nat64) {
    let logEntry : LogEntry = {
      itemType = itemType;
      user = user;
      amount = amount;
      tokenID = tokenID;
      timestamp = timestamp;
    };
    transactionLogs := Array.append(transactionLogs, [logEntry]);
  };

  // Function to log transactions with amount
  func logTransaction(itemType : ItemType, user : Principal, amount : Nat, timestamp : Nat64) {
    addLogEntry(itemType, user, ?amount, null, timestamp);
  };

  // Function to log transactions with tokenID
  func logTransactionWithTokenID(itemType : ItemType, user : Principal, tokenID : TokenID, timestamp : Nat64) {
    addLogEntry(itemType, user, null, ?tokenID, timestamp);
  };

  // Function to retrieve logs for a specific user and item type
  public query func getTransactionLogs(user : Principal, itemType : ItemType) : async [LogEntry] {
    return Array.filter<LogEntry>(
      transactionLogs,
      func(log : LogEntry) : Bool {
        log.user == user and log.itemType == itemType
      },
    );
  };

  public query func getMintedInfo(user : Principal) : async {
    shards : Nat;
    flux : Nat;
    chests : { quantity : Nat; tokenIDs : [TokenID] };
    gameNFTs : { quantity : Nat; tokenIDs : [TokenID] };
  } {
    let shards = switch (mintedShardsMap.get(user)) {
      case (null) 0;
      case (?shardsData) shardsData.quantity;
    };

    let flux = switch (mintedFluxMap.get(user)) {
      case (null) 0;
      case (?fluxData) fluxData.quantity;
    };

    let chests = switch (mintedChestsMap.get(user)) {
      case (null) ({ quantity = 0; tokenIDs = [] });
      case (?chestsData) chestsData;
    };

    let gameNFTs = switch (mintedGameNFTsMap.get(user)) {
      case (null) ({ quantity = 0; tokenIDs = [] });
      case (?gameNFTsData) gameNFTsData;
    };

    return {
      shards = shards;
      flux = flux;
      chests = chests;
      gameNFTs = gameNFTs;
    };
  };

  //--
  // Referrals

  type UUID = Text;
  type TierID = Nat;

  type RefAccount = {
    playerID : Principal;
    refByUUID : UUID;
    uuid : UUID;
    alias : Text;
    tiers : [Tier];
    tokens : [Token];
  };
  type Tier = {
    id : TierID;
    title : Text;
    desc : Text;
    status : Text;
    token : Token;
  };
  type Token = {
    title : Text;
    amount : Nat;
  };
  type RefAccView = {
    playerID : Principal;
    playerName : Text;
    currentTier : Tier;
    multiplier : Float;
    netWorth : Nat;
    topPlayers : [TopView];
    topPosition : Nat;
    topTokenAmount : (Nat, Text);
    signupTokenSum : Nat;
    tierTokenSum : Nat;
    singupLink : Text;
  };
  type TopView = {
    playerName : Text;
    multiplier : Float;
    netWorth : Nat;
  };

  type Buffer = Buffer.Buffer<Tier>;
  private var tiers : Buffer = Buffer.Buffer<Tier>(0);

  type HashMapAcc = HashMap.HashMap<Principal, RefAccount>;
  private stable var _accounts : [(Principal, RefAccount)] = [];
  private var accounts : HashMapAcc = HashMap.fromIter(
    Iter.fromArray(_accounts),
    0,
    Principal.equal,
    Principal.hash,
  );

  system func preupgrade() {
    _accounts := Iter.toArray(accounts.entries());
  };
  system func postupgrade() {
    accounts := HashMap.fromIter(
      Iter.fromArray(_accounts),
      0,
      Principal.equal,
      Principal.hash,
    );
    _accounts := [];
  };

  public shared ({ caller }) func ref_enroll(signupCode : ?Text, alias : Text) : async (Bool, Text) {

    switch (accounts.get(caller)) {
      case null {
        let code : Text = switch (signupCode) {
          case (null) { "" };
          case (?value) { value };
        };

        switch (ref_id_from_uuid(code)) {
          case (null) {

            accounts.put(
              caller,
              {
                playerID = caller;
                refByUUID = "";
                uuid = await ref_uuid_gen();
                tiers = ref_tier_all_p();
                alias = alias;
                tokens = [];
                netWorth = 0.0;
                multiplier = 0.0; //not implemented
              },
            );
            _accounts := Iter.toArray(accounts.entries());

            let textNotfound = "Referral code not provided or code not found";
            return (true, "Account enrrolled" # ", " # textNotfound);
          };

          case (?_) {

            let (minted, text) = await ref_claim_referral(
              code,
              {
                title = "Referral Signup token";
                amount = 5;
              },
            );

            if (minted) {
              accounts.put(
                caller,
                {
                  playerID = caller;
                  refByUUID = if (minted) { code } else { "" };
                  uuid = await ref_uuid_gen();
                  alias = alias;
                  tiers = ref_tier_all_p();
                  tokens = [{
                    title = "Referral Signup token";
                    amount = 5;
                  }];
                  netWorth = 0.0;
                  multiplier = 0.0;
                },
              );
              _accounts := Iter.toArray(accounts.entries());
              return (true, "Account enrrolled" # ", " # text);
            };

            return (false, text);

          };
        };
      };
      case (?_) { return (false, "Error. Account exists.") };
    };
  };
  public func ref_enroll_by(uuid : ?Text, principal : Principal, alias : Text) : async (Bool, Text) {

    switch (accounts.get(principal)) {
      case null {
        let code : Text = switch (uuid) {
          case (null) { "" };
          case (?value) { value };
        };

        var id = ref_id_from_uuid(code);

        switch (id) {

          case (null) {
            accounts.put(
              principal,
              {
                playerID = principal;
                refByUUID = "";
                uuid = await ref_uuid_gen();
                alias = alias;
                tiers = ref_tier_all_p();
                tokens = [];
                netWorth = 0.0;
                multiplier = 0.0; //not implemented
              },
            );
            _accounts := Iter.toArray(accounts.entries());
            let nullUUID = "Signup code no provided or code not found";
            return (true, "Account enrrolled" # ", " # nullUUID);
          };

          case (?_) {

            let (minted, text) = await ref_claim_referral(
              code,
              {
                title = "Referral Signup token";
                amount = 5;
              },
            );

            if (minted) {
              accounts.put(
                principal,
                {
                  playerID = principal;
                  refByUUID = if (minted) { code } else { "" };
                  uuid = await ref_uuid_gen();
                  alias = alias;
                  tiers = ref_tier_all_p();
                  tokens = [{
                    title = "Referral Signup token";
                    amount = 5;
                  }];
                  netWorth = 0.0;
                  multiplier = 0.0;
                },
              );
              _accounts := Iter.toArray(accounts.entries());
              return (true, "Account enrrolled" # ", " # text);
            };

            return (false, text);

          };
        };
      };
      case (?_) { (false, "Error. Account exists.") };
    };
  };
  public query func ref_account_view(id : Principal) : async ?RefAccView {

    let account = switch (accounts.get(id)) {
      case null { return null };
      case (?acc) { acc };
    };

    let currentTier = switch (ref_tier_p(id)) {
      case null {
        {
          id = 3;
          title = "All tiers defeated";
          desc = "You reached a Master referral record";
          status = "Waiting for more tiers";
          token = { title = "No token"; amount = 0 };
        };
      };
      case (?tier) tier;
    };

    let (
      multiplier,
      networth,
      tierTokenSum,
      signupTokenSum,
    ) = ref_tokenomics(account);

    let pageTop10 = 0;

    return ?({
      playerID = id;
      playerName = account.alias;
      currentTier = currentTier;
      multiplier = multiplier;
      netWorth = networth;
      tierTokenSum = tierTokenSum;
      signupTokenSum = signupTokenSum;
      topPlayers = ref_top_view(pageTop10);
      topPosition = ref_player_rank(id);
      topTokenAmount = ref_top_prize(id);
      singupLink = ref_signup_link(id);
    });
  };
  public query func ref_account_by(id : Principal) : async ?RefAccount {
    return accounts.get(id);
  };
  public query ({ caller }) func ref_account() : async ?RefAccount {
    return accounts.get(caller);
  };
  public query func ref_account_all() : async [(Text, Principal)] {
    let account = Iter.toArray(accounts.vals());
    let buffer = Buffer.Buffer<(Text, Principal)>(account.size());
    for (acc in account.vals()) buffer.add(acc.alias, acc.playerID);
    return Buffer.toArray(buffer);
  };
  public func ref_claim_top(id : Principal, day : Nat) : async (Bool, Text) {
    let account = switch (accounts.get(id)) {
      case null { return (false, "Account not found") };
      case (?account) { account };
    };

    if (day == 1) {

      let (tokenAmount, _) = ref_top_prize(id);

      if (tokenAmount > 0) {

        let (multiplier, _, _, _) = ref_tokenomics(account);
        let total = ref_token_amount(multiplier, tokenAmount);
        let (minted, _) = await mint(id, total);

        if (minted) {

          let token : Token = {
            title = "Weekly Top Player Token";
            amount = total;
          };

          let updatedTokens = Array.append(
            account.tokens,
            [token],
          );

          let updatedAccount : RefAccount = {
            playerID = account.playerID;
            refByUUID = account.refByUUID;
            uuid = account.uuid;
            alias = account.alias;
            tiers = account.tiers;
            tokens = updatedTokens;
          };

          accounts.put(id, updatedAccount);
          _accounts := Iter.toArray(accounts.entries());

          return (true, "Weekly top player token claimed: ");
        } else {
          return (false, "Error minting weekly top player token");
        };
      } else {
        return (false, "Player not in top 10.");
      };
    } else {
      return (false, "Only on moday's may be claimed");
    };
  };
  public func ref_claim_tier(id : Principal) : async (Bool, Text) {

    let (tierStatus, tierID) = switch (ref_tier_p(id)) {
      case null { return (false, "Reached all tiers.") };
      case (?tier) { (tier.status, tier.id) };
    };

    if (tierStatus == "No more tiers") { return (false, "No more tiers") };
    if (tierStatus == "complete") { return (false, "Tier already completed") };

    switch (accounts.get(id)) {
      case null { return (false, "Player not found.") };

      case (?account) {

        let tokenAmount = account.tiers[tierID].token.amount;
        let (multiplier, _, _, _) = ref_tokenomics(account);
        let total = ref_token_amount(multiplier, tokenAmount);
        let (minted, result) = await mint(id, total);

        if (minted) {

          let updTiers = Array.tabulate<Tier>(
            Array.size(account.tiers),
            func(i : Nat) : Tier {
              if (i == tierID) {
                let updTier : Tier = {
                  id = account.tiers[i].id;
                  title = account.tiers[i].title;
                  desc = account.tiers[i].desc;
                  status = "Complete";
                  token = {
                    title = account.tiers[i].token.title;
                    amount = total;
                  };
                };
                return updTier;
              } else {
                return account.tiers[i];
              };
            },
          );

          let updAcc : RefAccount = {
            playerID = account.playerID;
            refByUUID = account.refByUUID;
            uuid = account.uuid;
            alias = account.alias;
            tiers = updTiers;
            tokens = account.tokens;
          };

          accounts.put(id, updAcc);
          _accounts := Iter.toArray(accounts.entries());

          return (true, "Tier complete, token minted");
        } else {
          return (false, result);
        };
      };
    };
  };
  public func ref_id_gen() : async Principal {

    let randomBytes = await Random.blob();
    let randomArray = Blob.toArray(randomBytes);

    let truncatedBytes = Array.tabulate<Nat8>(
      29,
      func(i : Nat) : Nat8 {
        if (i < Array.size(randomArray)) {
          randomArray[i];
        } else 0;
      },
    );

    return Principal.fromBlob(
      Blob.fromArray(truncatedBytes)
    );
  };

  private func ref_tier_all_p() : [Tier] {

    if (tiers.size() == 0) {

      let missionTier : Tier = {
        id = 0;
        title = "Tier 1 Mission";
        desc = "Complete mission 1 and get 10 tokens free";
        status = "Progress";
        token = { title = "Tier 1 mission token"; amount = 10 };
      };
      tiers.add(missionTier);

      let discordTier : Tier = {
        id = 1;
        title = "Tier 2 Discord";
        desc = "Join Cosmicrafts Discord server and recieve 10 tokens for free";
        status = "Progress";
        token = { title = "Tier 2 Discord token"; amount = 10 };
      };
      tiers.add(discordTier);

      let tweeterTier : Tier = {
        id = 2;
        title = "Tier 3 Tweeter";
        desc = "Three Tweeter tags and recieve 20 tokens for free";
        status = "Progress";
        token = { title = "Tier 3 Tweeter token"; amount = 10 };
      };
      tiers.add(tweeterTier);

      let tiersComplete : Tier = {
        id = 3;
        title = "All tiers defeated";
        desc = "You reached a Master referral record";
        status = "Waiting for more tiers";
        token = { title = "No token"; amount = 0 };
      };
      tiers.add(tiersComplete);

    };

    return Buffer.toArray(tiers);
  };
  private func ref_tier_p(playerId : Principal) : ?Tier {
    let player = accounts.get(playerId);
    switch (player) {
      case (null) { return null };
      case (?player) {
        for (
          tier in player.tiers.vals()
        ) {
          if (tier.status == "Progress") {
            return ?tier;
          };
        };
        return null;
      };
    };
  };
  private func ref_player_rank(id : Principal) : Nat {

    let playersArray = Buffer.fromArray<(Principal, RefAccount)>(
      Iter.toArray(accounts.entries())
    );

    var playersWithTokenSums : [(Principal, Nat)] = [];

    for (i in Iter.range(0, playersArray.size() - 1)) {

      let (principal, account) = playersArray.get(i);
      let (_, tokenSum, _, _) = ref_tokenomics(account);

      playersWithTokenSums := Array.append(
        playersWithTokenSums,
        [(principal, tokenSum)],
      );
    };

    let sortedPlayers = Array.sort(
      playersWithTokenSums,
      func(
        a : (Principal, Nat),
        b : (Principal, Nat),
      ) : {
        #less;
        #equal;
        #greater;
      } {
        if (a.1 > b.1) {
          #less;
        } else if (a.1 < b.1) {
          #greater;
        } else {
          #equal;
        };
      },
    );

    var position : Nat = 0;
    for ((principal, _) in sortedPlayers.vals()) {
      if (principal == id) {
        return position + 1;
      };
      position += 1;
    };

    0;
  };
  private func ref_top_prize(id : Principal) : (Nat, Text) {

    let topPlayers = ref_top_view(0);

    switch (accounts.get(id)) {
      case (null) { return (0, "Account not found") };

      case (?account) {
        for (player in topPlayers.vals()) {
          if (player.playerName == account.alias) {
            for (token in account.tokens.vals()) {
              if (token.title == "Weekly Top Player Token") {
                return (token.amount, "Tokens claimed");
              };
            };
            let prizeAmount = 10;
            let (multiplier, _, _, _) = ref_tokenomics(account);
            let total = ref_token_amount(multiplier, prizeAmount);
            return (total, "You are in, waiting for monday.");
          };
        };

        return (0, "Not clasified");
      };
    };
  };
  private func ref_tokenomics(acc : RefAccount) : (Float, Nat, Nat, Nat) {

    var multiplier : Float = 0.0;
    let tierTokenSum : Nat = ref_tier_token_sum(acc);
    let signupTokenSum : Nat = ref_token_sum(acc);
    let networth : Nat = tierTokenSum + signupTokenSum;

    if (networth <= 10) {
      multiplier := 1.3;
    } else if (networth <= 20) {
      multiplier := 2.2;
    } else {
      multiplier := 3.7;
    };

    (
      multiplier,
      networth,
      tierTokenSum,
      signupTokenSum,
    );
  };
  private func ref_token_amount(multiplier : Float, nTokens : Nat) : Nat {
    let nat64 = Nat64.fromNat(nTokens);
    let int64 = Int64.fromNat64(nat64);
    let totalTokens = Float.fromInt64(int64);
    let total = Float.toInt64(multiplier * totalTokens);
    let nat = Int64.toNat64(total);
    return Nat64.toNat(nat);
  };
  private func ref_token_sum(account : RefAccount) : Nat {
    return Array.foldLeft<Token, Nat>(
      account.tokens,
      0,
      func(acc, token) {
        acc + token.amount;
      },
    );
  };
  private func ref_tier_token_sum(account : RefAccount) : Nat {
    return Array.foldLeft<Tier, Nat>(
      account.tiers,
      0,
      func(acc, tier) {
        if (tier.status == "Complete") {
          acc + tier.token.amount;
        } else {
          acc;
        };
      },
    );
  };
  private func ref_top_view(page : Nat) : [TopView] {

    var playersWithTokenSums : [(Principal, RefAccount, Nat)] = [];
    let playersArray = Buffer.fromArray<(Principal, RefAccount)>(
      Iter.toArray(accounts.entries())
    );

    for (i in Iter.range(0, playersArray.size() - 1)) {

      let (principal, account) = playersArray.get(i);
      let (multiplier, networth, _, _) = ref_tokenomics(account);
      let tokenSum = networth;

      playersWithTokenSums := Array.append(
        playersWithTokenSums,
        [(
          principal,
          {
            playerID = account.playerID;
            refByUUID = account.refByUUID;
            uuid = account.uuid;
            alias = account.alias;
            tiers = account.tiers;
            tokens = account.tokens;
            netWorth = networth;
            multiplier = multiplier;
          },
          tokenSum,
        )],
      );
    };

    let sorted = Array.sort(
      playersWithTokenSums,
      func(
        a : (Principal, RefAccount, Nat),
        b : (Principal, RefAccount, Nat),
      ) : {
        #less;
        #equal;
        #greater;
      } {
        if (a.2 > b.2) {
          #less;
        } else if (a.2 < b.2) {
          #greater;
        } else {
          #equal;
        };
      },
    );

    let start = page * 10;
    let end = if (
      start + 10 > Array.size(sorted)
    ) {
      Array.size(sorted);
    } else { start + 10 };

    let paginated = Iter.toArray(
      Array.slice(
        sorted,
        start,
        end,
      )
    );

    var viewArray : [TopView] = [];

    for ((_, refAccount, _) in paginated.vals()) {
      let (m, n, _, _) = ref_tokenomics(refAccount);
      let rowView : TopView = {
        playerName = refAccount.alias;
        multiplier = m;
        netWorth = n;
      };
      viewArray := Array.append(viewArray, [rowView]);
    };

    viewArray;

  };
  private func ref_claim_referral(code : UUID, token : Token) : async (Bool, Text) {

    let signupToken : Token = {
      title = "Referral Signup token";
      amount = 5;
    };

    let id = switch (ref_id_from_uuid(code)) {
      case null { return (false, "Code not found") };
      case (?id) { id };
    };

    switch (accounts.get(id)) {
      case null { return (false, "Player principal not found.") };

      case (?account) {

        if (account.refByUUID == code) {
          return (false, "Error. Code already redeemed");
        };

        let size = (Array.size(account.tokens));

        if (Array.size(account.tokens) > 3) {
          return (false, "Reached max referral per player");
        };

        if (size > 0) {

          let (multiplier, _, _, _) = ref_tokenomics(account);
          let total = ref_token_amount(multiplier, signupToken.amount);
          let (minted, result) = await mint(id, total);

          if (minted) {

            let updAcc : RefAccount = {
              playerID = account.playerID;
              refByUUID = account.refByUUID;
              uuid = account.uuid;
              alias = account.alias;
              tiers = account.tiers;
              tokens = Array.append(
                account.tokens,
                [{ title = token.title; amount = total }],
              );
            };

            accounts.put(account.playerID, updAcc);
            _accounts := Iter.toArray(accounts.entries());

            return (true, "Referral token added to account.");
          } else {
            return (false, "Error miniting tokens." # result);
          };
        } else {

          let (multiplier, _, _, _) = ref_tokenomics(account);
          let total = ref_token_amount(multiplier, signupToken.amount);

          let (minted, result) = await mint(id, total);

          if (minted) {

            let updAcc : RefAccount = {
              playerID = account.playerID;
              refByUUID = account.refByUUID;
              uuid = account.uuid;
              alias = account.alias;
              tiers = account.tiers;
              tokens = [{ title = token.title; amount = total }];
            };

            accounts.put(account.playerID, updAcc);
            _accounts := Iter.toArray(accounts.entries());

            return (true, "First referral token added to account. ");
          } else {
            return (false, "Error miniting tokens." # result);
          };
        };

        return (false, "Mint token error.");

      };
    };
  };
  private func ref_signup_link(id : Principal) : Text {
    let route = "https://cosmicrafts.com/signup_prom/";
    let err = "Account not found";
    switch (accounts.get(id)) {
      case (?refAccount) {
        let uuid : Text = refAccount.uuid;
        route # uuid;
      };
      case null err;
    };
  };
  private func ref_id_from_uuid(uuid : UUID) : ?Principal {
    let mappedIter = Iter.filter<(Principal, RefAccount)>(
      Iter.fromArray(_accounts),
      func(x : (Principal, RefAccount)) : Bool {
        let acc = x.1;
        if (acc.uuid == uuid) {
          return true;
        };
        return false;
      },
    );
    switch (mappedIter.next()) {
      case (null) { null };
      case (?(principal, _)) { ?principal };
    };
  };
  private func ref_uuid_gen() : async Text {
    var uuid : Nat = 0;
    let randomBytes = await Random.blob();
    let byteArray = Blob.toArray(randomBytes);
    for (i in Iter.range(0, 7)) {
      uuid := Nat.add(
        Nat.bitshiftLeft(uuid, 8),
        Nat8.toNat(
          byteArray[i]
        ),
      );
    };
    uuid := uuid % 2147483647;
    return Nat.toText(uuid);
  };

  private func mint(principalId : Principal, amount : Nat) : async (Bool, Text) {
    let _tokenXArgs : TypesICRC1.Mint = {
      to = { owner = principalId; subaccount = null };
      amount = amount;
      memo = null;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
    };
    let tokenXMinted = await shards.mint(_tokenXArgs);
    let tokenXResult = switch (tokenXMinted) {
      case (#Ok(_tid)) "{\"token\":\"Token X\", \"transaction_id\": " # Nat.toText(_tid) # ", \"amount\": " # Nat.toText(amount) # "}";
      case (#Err(_e)) Utils.handleMintError("Token X", _e);
    };
    let success = switch (tokenXMinted) {
      case (#Ok(_tid)) true;
      case (#Err(_e)) false;
    };
    (success, tokenXResult);
  };

  //--
  // Tournaments
  stable var tournaments : [Tournament] = [];
  stable var matches : [Match] = [];
  stable var feedback : [{
    principal : Principal;
    tournamentId : Nat;
    feedback : Text;
  }] = [];
  stable var disputes : [{
    principal : Principal;
    matchId : Nat;
    reason : Text;
    status : Text;
  }] = [];

  type Tournament = {
    id : Nat;
    name : Text;
    startDate : Time.Time;
    prizePool : Text;
    expirationDate : Time.Time;
    participants : [Principal];
    registeredParticipants : [Principal];
    isActive : Bool;
    bracketCreated : Bool;
    matchCounter : Nat; // Add matchCounter to each tournament
  };

  type Match = {
    id : Nat;
    tournamentId : Nat;
    participants : [Principal];
    result : ?{ winner : Principal; score : Text };
    status : Text;
    nextMatchId : ?Nat; // Track the next match
  };

  public shared ({ caller }) func createTournament(name : Text, startDate : Time.Time, prizePool : Text, expirationDate : Time.Time) : async Nat {
    if (
      caller != Principal.fromText("vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae") and
      caller != Principal.fromText("bdycp-b54e6-fvsng-ouies-a6zfm-khbnh-wcq3j-pv7qt-gywe2-em245-3ae")
    ) {
      return 0;
    };

    let id = tournaments.size();
    let buffer = Buffer.Buffer<Tournament>(tournaments.size() + 1);
    for (tournament in tournaments.vals()) {
      buffer.add(tournament);
    };
    buffer.add({
      id = id;
      name = name;
      startDate = startDate;
      prizePool = prizePool;
      expirationDate = expirationDate;
      participants = [];
      registeredParticipants = [];
      isActive = true;
      bracketCreated = false;
      matchCounter = 0 // Initialize matchCounter
    });
    tournaments := Buffer.toArray(buffer);
    return id;
  };

  public shared ({ caller }) func joinTournament(tournamentId : Nat) : async Bool {
    if (tournamentId >= tournaments.size()) {
      return false;
    };

    let tournament = tournaments[tournamentId];

    if (Array.indexOf<Principal>(caller, tournament.participants, func(a : Principal, b : Principal) : Bool { a == b }) != null) {
      return false;
    };

    var updatedParticipants = Buffer.Buffer<Principal>(tournament.participants.size() + 1);
    for (participant in tournament.participants.vals()) {
      updatedParticipants.add(participant);
    };
    updatedParticipants.add(caller);

    var updatedRegisteredParticipants = Buffer.Buffer<Principal>(tournament.registeredParticipants.size() + 1);
    for (participant in tournament.registeredParticipants.vals()) {
      updatedRegisteredParticipants.add(participant);
    };
    updatedRegisteredParticipants.add(caller);

    let updatedTournament = {
      id = tournament.id;
      name = tournament.name;
      startDate = tournament.startDate;
      prizePool = tournament.prizePool;
      expirationDate = tournament.expirationDate;
      participants = Buffer.toArray(updatedParticipants);
      registeredParticipants = Buffer.toArray(updatedRegisteredParticipants);
      isActive = tournament.isActive;
      bracketCreated = tournament.bracketCreated;
      matchCounter = tournament.matchCounter;
    };

    tournaments := Array.tabulate(
      tournaments.size(),
      func(i : Nat) : Tournament {
        if (i == tournamentId) {
          updatedTournament;
        } else {
          tournaments[i];
        };
      },
    );

    return true;
  };

  public query func getRegisteredUsers(tournamentId : Nat) : async [Principal] {
    if (tournamentId >= tournaments.size()) {
      return [];
    };

    let tournament : Tournament = tournaments[tournamentId];
    return tournament.registeredParticipants;
  };

  public shared ({ caller }) func submitFeedback(_tournamentId : Nat, feedbackText : Text) : async Bool {
    let newFeedback = Buffer.Buffer<{ principal : Principal; tournamentId : Nat; feedback : Text }>(feedback.size() + 1);
    for (entry in feedback.vals()) {
      newFeedback.add(entry);
    };
    newFeedback.add({
      principal = caller;
      tournamentId = _tournamentId;
      feedback = feedbackText;
    });
    feedback := Buffer.toArray(newFeedback);
    return true;
  };

  public shared ({ caller }) func submitMatchResult(tournamentId : Nat, matchId : Nat, score : Text) : async Bool {
    let matchOpt = Array.find<Match>(matches, func(m : Match) : Bool { m.id == matchId and m.tournamentId == tournamentId });
    switch (matchOpt) {
      case (?match) {
        let isParticipant = Array.find<Principal>(match.participants, func(p : Principal) : Bool { p == caller }) != null;
        if (not isParticipant) {
          return false;
        };

        var updatedMatches = Buffer.Buffer<Match>(matches.size());
        for (m in matches.vals()) {
          if (m.id == matchId and m.tournamentId == tournamentId) {
            updatedMatches.add({
              id = m.id;
              tournamentId = m.tournamentId;
              participants = m.participants;
              result = ?{ winner = caller; score = score };
              status = "pending verification";
              nextMatchId = m.nextMatchId;
            });
          } else {
            updatedMatches.add(m);
          };
        };
        matches := Buffer.toArray(updatedMatches);
        return true;
      };
      case null {
        return false;
      };
    };
  };

  public shared ({ caller }) func disputeMatch(tournamentId : Nat, matchId : Nat, reason : Text) : async Bool {
    let matchExists = Array.find(matches, func(m : Match) : Bool { m.id == matchId and m.tournamentId == tournamentId }) != null;
    if (not matchExists) {
      return false;
    };

    let newDispute = {
      principal = caller;
      matchId = matchId;
      reason = reason;
      status = "pending";
    };
    let updatedDisputes = Buffer.Buffer<{ principal : Principal; matchId : Nat; reason : Text; status : Text }>(disputes.size() + 1);
    for (dispute in disputes.vals()) {
      updatedDisputes.add(dispute);
    };
    updatedDisputes.add(newDispute);
    disputes := Buffer.toArray(updatedDisputes);

    return true;
  };

  public shared ({ caller }) func adminUpdateMatch(tournamentId : Nat, matchId : Nat, winnerIndex : Nat, score : Text) : async Bool {
    if (
      caller != Principal.fromText("vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae") and
      caller != Principal.fromText("bdycp-b54e6-fvsng-ouies-a6zfm-khbnh-wcq3j-pv7qt-gywe2-em245-3ae")
    ) {
      return false;
    };

    let matchOpt = Array.find<Match>(matches, func(m : Match) : Bool { m.id == matchId and m.tournamentId == tournamentId });
    switch (matchOpt) {
      case (?match) {
        if (winnerIndex >= Array.size<Principal>(match.participants)) {
          return false; // Invalid winner index
        };

        let winnerPrincipal = match.participants[winnerIndex];

        var updatedMatches = Buffer.Buffer<Match>(matches.size());
        for (m in matches.vals()) {
          if (m.id == matchId and m.tournamentId == tournamentId) {
            updatedMatches.add({
              id = m.id;
              tournamentId = m.tournamentId;
              participants = m.participants;
              result = ?{ winner = winnerPrincipal; score = score };
              status = "verified";
              nextMatchId = m.nextMatchId;
            });
          } else {
            updatedMatches.add(m);
          };
        };
        matches := Buffer.toArray(updatedMatches);

        // Update the bracket directly by advancing the winner
        Debug.print("Admin verified match: " # Nat.toText(matchId) # " with winner: " # Principal.toText(winnerPrincipal));
        ignore updateBracketAfterMatchUpdate(match.tournamentId, match.id, winnerPrincipal);

        return true;
      };
      case null {
        return false;
      };
    };
  };

  // Calculate the base-2 logarithm of a number
  func log2(x : Nat) : Nat {
    var result = 0;
    var value = x;
    while (value > 1) {
      value /= 2;
      result += 1;
    };
    return result;
  };

  // Helper function to update the bracket after a match result is verified
  public shared func updateBracketAfterMatchUpdate(tournamentId : Nat, matchId : Nat, winner : Principal) : async () {
    Debug.print("Starting updateBracketAfterMatchUpdate");
    Debug.print("Updated Match ID: " # Nat.toText(matchId));
    Debug.print("Winner: " # Principal.toText(winner));

    // Log the current state of the matches
    for (i in Iter.range(0, matches.size() - 1)) {
      let match = matches[i];
      Debug.print("Current Match: " # matchToString(match));
    };

    let updatedMatchOpt = Array.find<Match>(matches, func(m : Match) : Bool { m.id == matchId and m.tournamentId == tournamentId });
    switch (updatedMatchOpt) {
      case (?updatedMatch) {
        switch (updatedMatch.nextMatchId) {
          case (?nextMatchId) {
            Debug.print("Next match ID is not null: " # Nat.toText(nextMatchId));

            let nextMatchOpt = Array.find<Match>(matches, func(m : Match) : Bool { m.id == nextMatchId and m.tournamentId == tournamentId });
            switch (nextMatchOpt) {
              case (?nextMatch) {
                Debug.print("Next match found with ID: " # Nat.toText(nextMatchId));

                var updatedParticipants = Buffer.Buffer<Principal>(2);
                var replaced = false;

                for (p in nextMatch.participants.vals()) {
                  if (p == Principal.fromText("2vxsx-fae") and not replaced) {
                    updatedParticipants.add(winner);
                    replaced := true;
                  } else {
                    updatedParticipants.add(p);
                  };
                };

                Debug.print("Before update: " # participantsToString(nextMatch.participants));
                Debug.print("After update: " # participantsToString(Buffer.toArray(updatedParticipants)));

                let updatedNextMatch = {
                  id = nextMatch.id;
                  tournamentId = nextMatch.tournamentId;
                  participants = Buffer.toArray(updatedParticipants);
                  result = nextMatch.result;
                  status = nextMatch.status;
                  nextMatchId = nextMatch.nextMatchId;
                };

                // Update the next match in the matches array using Array.map
                matches := Array.map<Match, Match>(
                  matches,
                  func(m : Match) : Match {
                    if (m.id == nextMatchId and m.tournamentId == tournamentId) {
                      updatedNextMatch;
                    } else {
                      m;
                    };
                  },
                );
                Debug.print("Updated match in the matches map with ID: " # Nat.toText(nextMatchId));
              };
              case null {
                Debug.print("Error: Next match not found with ID: " # Nat.toText(nextMatchId));
              };
            };
          };
          case null {
            Debug.print("Next match ID is null for match ID: " # Nat.toText(matchId));
          };
        };
      };
      case null {
        Debug.print("Match not found for ID: " # Nat.toText(matchId));
      };
    };

    // Log the updated state of the matches
    for (i in Iter.range(0, matches.size() - 1)) {
      let match = matches[i];
      Debug.print("Updated Match: " # matchToString(match));
    };
  };

  private func matchToString(match : Match) : Text {
    return "Match ID: " # Nat.toText(match.id) # ", Participants: " # participantsToString(match.participants) # ", Result: " # (switch (match.result) { case (?res) { "Winner: " # Principal.toText(res.winner) # ", Score: " # res.score }; case null { "pending" } }) # ", Next Match ID: " # (switch (match.nextMatchId) { case (?nextId) { Nat.toText(nextId) }; case null { "none" } });
  };

  private func participantsToString(participants : [Principal]) : Text {
    var text = "";
    var first = true;
    for (participant in participants.vals()) {
      if (not first) {
        text #= ", ";
      };
      first := false;
      text #= Principal.toText(participant);
    };
    return text;
  };

  public shared func updateBracket(tournamentId : Nat) : async Bool {
    if (tournamentId >= tournaments.size()) {
      // Debug.print("Tournament does not exist.");
      return false;
    };

    var tournament = tournaments[tournamentId];
    let participants = tournament.participants;

    // Close registration if not already closed
    if (not tournament.bracketCreated) {
      let updatedTournament = {
        id = tournament.id;
        name = tournament.name;
        startDate = tournament.startDate;
        prizePool = tournament.prizePool;
        expirationDate = tournament.expirationDate;
        participants = tournament.participants;
        registeredParticipants = tournament.registeredParticipants;
        isActive = false;
        bracketCreated = true;
        matchCounter = tournament.matchCounter;
      };

      tournaments := Array.tabulate(
        tournaments.size(),
        func(i : Nat) : Tournament {
          if (i == tournamentId) {
            updatedTournament;
          } else {
            tournaments[i];
          };
        },
      );
    };

    // Obtain a fresh blob of entropy
    let entropy = await Random.blob();
    let random = Random.Finite(entropy);

    // Calculate total participants including byes
    var totalParticipants = 1;
    while (totalParticipants < participants.size()) {
      totalParticipants *= 2;
    };

    let byesCount = Nat.sub(totalParticipants, participants.size());
    var allParticipants = Buffer.Buffer<Principal>(totalParticipants);
    for (p in participants.vals()) {
      allParticipants.add(p);
    };
    for (i in Iter.range(0, byesCount - 1)) {
      allParticipants.add(Principal.fromText("2vxsx-fae"));
    };

    // Shuffle all participants and byes together
    var shuffledParticipants = Array.thaw<Principal>(Buffer.toArray(allParticipants));
    var i = shuffledParticipants.size();
    while (i > 1) {
      i -= 1;
      let j = switch (random.range(32)) {
        case (?value) { value % (i + 1) };
        case null { i };
      };
      let temp = shuffledParticipants[i];
      shuffledParticipants[i] := shuffledParticipants[j];
      shuffledParticipants[j] := temp;
    };

    Debug.print("Total participants after adjustment: " # Nat.toText(totalParticipants));

    // Store the total participants count for round 1
    let totalParticipantsRound1 = totalParticipants;

    // Create initial round matches with nextMatchId
    let roundMatches = Buffer.Buffer<Match>(0);
    var matchId = tournament.matchCounter;
    var nextMatchIdBase = totalParticipants / 2;
    for (i in Iter.range(0, totalParticipants / 2 - 1)) {
      let p1 = shuffledParticipants[i * 2];
      let p2 = shuffledParticipants[i * 2 + 1];
      let currentNextMatchId = ?(nextMatchIdBase + (i / 2));
      roundMatches.add({
        id = matchId;
        tournamentId = tournamentId;
        participants = [p1, p2];
        result = null;
        status = "scheduled";
        nextMatchId = currentNextMatchId;
      });
      Debug.print("Created match: " # Nat.toText(matchId) # " with participants: " # Principal.toText(p1) # " vs " # Principal.toText(p2) # " nextMatchId: " # (switch (currentNextMatchId) { case (?id) { Nat.toText(id) }; case null { "none" } }));
      matchId += 1;
    };
    nextMatchIdBase /= 2;

    // Update matchCounter in the tournament
    let updatedTournament = {
      id = tournament.id;
      name = tournament.name;
      startDate = tournament.startDate;
      prizePool = tournament.prizePool;
      expirationDate = tournament.expirationDate;
      participants = tournament.participants;
      registeredParticipants = tournament.registeredParticipants;
      isActive = tournament.isActive;
      bracketCreated = tournament.bracketCreated;
      matchCounter = matchId // Update matchCounter
    };

    tournaments := Array.tabulate(
      tournaments.size(),
      func(i : Nat) : Tournament {
        if (i == tournamentId) {
          updatedTournament;
        } else {
          tournaments[i];
        };
      },
    );

    // Function to recursively create matches for all rounds
    func createAllRounds(totalRounds : Nat, currentRound : Nat, matchId : Nat) : Buffer.Buffer<Match> {
      let newMatches = Buffer.Buffer<Match>(0);
      if (currentRound >= totalRounds) {
        return newMatches;
      };

      let numMatches = (totalParticipantsRound1 / (2 ** (currentRound + 1)));
      for (i in Iter.range(0, numMatches - 1)) {
        // Calculate next match ID correctly
        let nextMatchIdOpt = if (currentRound + 1 == totalRounds) {
          null;
        } else {
          ?(matchId + (i / 2) + numMatches);
        };

        newMatches.add({
          id = matchId + i;
          tournamentId = tournamentId;
          participants = [Principal.fromText("2vxsx-fae"), Principal.fromText("2vxsx-fae")];
          result = null;
          status = "scheduled";
          nextMatchId = nextMatchIdOpt;
        });
        Debug.print("Created next round match: " # Nat.toText(matchId + i) # " with nextMatchId: " # (switch (nextMatchIdOpt) { case (?id) { Nat.toText(id) }; case null { "none" } }));
      };

      // Recursively create next round matches
      let nextRoundMatches = createAllRounds(totalRounds, currentRound + 1, matchId + numMatches);
      for (match in nextRoundMatches.vals()) {
        newMatches.add(match);
      };

      return newMatches;
    };

    let totalRounds = log2(totalParticipantsRound1);
    Debug.print("Total rounds: " # Nat.toText(totalRounds));
    let subsequentRounds = createAllRounds(totalRounds, 1, matchId);

    // Update the stable variable matches
    var updatedMatches = Buffer.Buffer<Match>(matches.size() + roundMatches.size() + subsequentRounds.size());
    for (match in matches.vals()) {
      updatedMatches.add(match);
    };
    for (newMatch in roundMatches.vals()) {
      updatedMatches.add(newMatch);
    };
    for (subsequentMatch in subsequentRounds.vals()) {
      updatedMatches.add(subsequentMatch);
    };
    matches := Buffer.toArray(updatedMatches);

    // Manually create text representation for matches
    var matchesText = "";
    var firstMatch = true;
    for (match in matches.vals()) {
      if (not firstMatch) {
        matchesText #= ", ";
      };
      firstMatch := false;
      let nextMatchIdText = switch (match.nextMatchId) {
        case (?id) { Nat.toText(id) };
        case null { "none" };
      };
      matchesText #= "Match ID: " # Nat.toText(match.id) # " nextMatchId: " # nextMatchIdText;
    };

    Debug.print("Bracket created with matches: " # matchesText);

    return true;
  };

  public query func getActiveTournaments() : async [Tournament] {
    return Array.filter<Tournament>(tournaments, func(t : Tournament) : Bool { t.isActive });
  };

  public query func getInactiveTournaments() : async [Tournament] {
    return Array.filter<Tournament>(tournaments, func(t : Tournament) : Bool { not t.isActive });
  };

  public query func getAllTournaments() : async [Tournament] {
    return tournaments;
  };

  public query func getTournamentBracket(tournamentId : Nat) : async {
    matches : [Match];
  } {
    return {
      matches = Array.filter<Match>(matches, func(m : Match) : Bool { m.tournamentId == tournamentId });
    };
  };

  public shared func deleteAllTournaments() : async Bool {
    tournaments := [];
    matches := [];
    return true;
  };
};
