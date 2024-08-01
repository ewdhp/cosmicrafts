# `cosmicrafts`

    let shards: ICRC1Interface = actor("bw4dl-smaaa-aaaaa-qaacq-cai") : ICRC1Interface;

    let flux: ICRC1Interface = actor("b77ix-eeaaa-aaaaa-qaada-cai") : ICRC1Interface;

    let gameNFTs: ICRC7Interface = actor("be2us-64aaa-aaaaa-qaabq-cai") : ICRC7Interface;

    let chests: ICRC7Interface = actor("br5f7-7uaaa-aaaaa-qaaca-cai") : ICRC7Interface;

    //mainnet
    let shards: ICRC1Interface = actor("svcoe-6iaaa-aaaam-ab4rq-cai") : ICRC1Interface;

    let flux: ICRC1Interface = actor("plahz-wyaaa-aaaam-accta-cai") : ICRC1Interface;

    let gameNFTs: ICRC7Interface = actor("etqmj-zyaaa-aaaap-aakaq-cai") : ICRC7Interface;

    let chests: ICRC7Interface = actor("opcce-byaaa-aaaak-qcgda-cai") : ICRC7Interface;
,
    "gamenfts": {
      "main": "src/icrc7/gamenfts.mo",
      "type": "motoko"
    },
    "chests": {
      "main": "src/icrc7/chests.mo",
      "type": "motoko"
    },
    "shards": {
      "main": "src/icrc1/Canisters/shards.mo",
      "type": "motoko"
    },
    "flux": {
      "main": "src/icrc1/Canisters/flux.mo",
      "type": "motoko"
    }


    // convert float xp into level nat
    public func calculateLevel(xp: Float) : Nat {
        let levelFloat = if (xp < 100.0) 1.0 else Float.trunc(Float.log(xp / 100.0) / Float.log(2.0)) + 1.0;
        let levelInt = Float.toInt(levelFloat);
        let levelNat64 = Nat64.fromIntWrap(levelInt);
        return Nat64.toNat(levelNat64);
    };


Key Areas in the Code
Reward Management:

Creating missions.
Cleaning up expired missions.
Adding progress to rewards.
Claiming rewards.
Retrieving unclaimed and unexpired rewards.
Player Management:

Registering a player.
Updating player information (username, avatar, description).
Adding friends.
Calculating player levels based on experience points.
Statistics Management:

Maintaining player game statistics.
Updating overall game statistics.
Retrieving player statistics.
Calculating average statistics.
Matchmaking:

Managing matchmaking status.
Activating player search status.
Cancelling matchmaking.
Retrieving match participants.
ICRC Token Management:

Minting and upgrading NFTs.
Handling chests and opening them.



dfx deploy cxp --ic --argument '( record { name = "Cosmicrafts XP"; symbol = "CXP"; decimals = 8; fee = 1; max_supply = 1_000_000_000_000_000_000_000_000; initial_balances = vec {
record { record { owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null; }; 100_000_000_000 } }; min_burn_amount = 1; minting_account = opt record { owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null; }; advanced_settings = null; })'

dfx deploy energy --ic --argument '( record { name = "Cosmicrafts Energy"; symbol = "NRG"; decimals = 8; fee = 1; max_supply = 1_000_000_000_000_000_000_000_000; initial_balances = vec {
record { record { owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null; }; 100_000_000_000 } }; min_burn_amount = 1; minting_account = opt record { owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null; }; advanced_settings = null; })'


dfx deploy flux --argument "(variant {Init =
record {
     token_symbol = \"FLX\";
     token_name = \"FLUX\";
     minting_account = record { owner = principal \"bkyz2-fmaaa-aaaaa-qaaaq-cai\" };
     transfer_fee = 1;
     metadata = vec {};
     feature_flags = opt record{icrc2 = true};
     initial_balances = vec { record { record { owner = principal \"bkyz2-fmaaa-aaaaa-qaaaq-cai\"; }; 0; }; };
     archive_options = record {
         num_blocks_to_archive = 1000;
         trigger_threshold = 2000;
         controller_id = principal \"bkyz2-fmaaa-aaaaa-qaaaq-cai\";
         cycles_for_archive_creation = opt 10000000000000;
     };
 }
})"


dfx canister uninstall-code etqmj-zyaaa-aaaap-aakaq-cai --ic
dfx canister uninstall-code b7g3n-niaaa-aaaaj-aadlq-cai --ic

dfx canister call etqmj-zyaaa-aaaap-aakaq-cai mint --ic
dfx canister call b7g3n-niaaa-aaaaj-aadlq-cai mint --ic

gccov-gnjwn-heylh-mzo3a-kdpre-vs75x-aa353-ixynu-qkmgn-l36pm-cae


dfx deploy icrc7 --argument '( record {owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null;}, record { "name" = "Cosmicrafts Avatars"; symbol = "CSA"; royalties = null; royaltyRecipient = null; description = null; image = null; supplyCap = null; })'


// cleanup matchmaking debug
    // Function to clean up inactive players from the matchmaking queue
    private func cleanupInactivePlayers() : async () {
        let currentTime = Nat64.fromIntWrap(Time.now());
        let inactivityThreshold = 3 * 60 * ONE_SECOND; // 3 minutes in nanoseconds

        for ((matchID, matchData) in searching.entries()) {
            if (matchData.player1.lastPlayerActive + inactivityThreshold < currentTime) {
                ignore searching.remove(matchID);
                ignore playerStatus.remove(matchData.player1.id);
            };
            switch (matchData.player2) {
                case (?player2) {
                    if (player2.lastPlayerActive + inactivityThreshold < currentTime) {
                        ignore searching.remove(matchID);
                        ignore playerStatus.remove(player2.id);
                    };
                };
                case (null) {};
            };
        };
    };

    // Schedule the cleanup task
    private func scheduleCleanupTask() : async () {
        while (true) {
            await cleanupInactivePlayers();
            // Wait for a specified interval before running the cleanup task again
            await sleep(ONE_SECOND * 180); // Run cleanup every 3 minutes
        };
    };

public shared func startTimer() : async () {
    // Schedule a task to run in 1 second
    ignore await Timer.setTimer(ONE_SECOND, async {
      // Code to execute after 1 second
      Debug.print("Timer executed!");
    });
  };

    // Call this function to start the cleanup task when the actor is initialized
    public shared ({ caller }) func initialize() : async () {
        ignore scheduleCleanupTask();
    };




// Mint Chests without await
public shared({ caller }) func openChests(chestID: Nat): async (Bool, Text) {
    // Perform ownership check
    let ownerof: TypesICRC7.OwnerResult = await chests.icrc7_owner_of(chestID);
    let _owner: TypesICRC7.Account = switch (ownerof) {
        case (#Ok(owner)) owner;
        case (#Err(_)) return (false, "{\"success\":false, \"message\":\"Chest not found\"}");
    };

    if (Principal.notEqual(_owner.owner, caller)) {
        return (false, "{\"success\":false, \"message\":\"Not the owner of the chest\"}");
    };

    // Immediate placeholder response to Unity
    let placeholderResponse = "{\"success\":true, \"message\":\"Chest opened successfully\", \"tokens\":[{\"token\":\"Shards\", \"amount\": 0}, {\"token\":\"Flux\", \"amount\": 0}]}";
    
    // Schedule background processing without waiting
    ignore _processChestContents(chestID, caller);

    // Burn the chest token asynchronously without waiting for the result
    ignore async {
        let _chestArgs: TypesICRC7.OpenArgs = {
            from = _owner;
            token_id = chestID;
        };
        await chests.openChest(_chestArgs);
    };

    return (true, placeholderResponse);
};

// Function to process chest contents in the background
private func _processChestContents(chestID: Nat, caller: Principal): async () {
    // Determine chest rarity based on metadata
    let metadataResult = await chests.icrc7_metadata(chestID);
    let rarity = switch (metadataResult) {
        case (#Ok(metadata)) getRarityFromMetadata(metadata);
        case (#Err(_)) 1;
    };

    let (shardsAmount, fluxAmount) = getTokensAmount(rarity);

    // Mint tokens in parallel
    let shardsMinting = async {
        // Mint shards tokens
        let _shardsArgs: TypesICRC1.Mint = {
            to = { owner = caller; subaccount = null };
            amount = shardsAmount;
            memo = null;
            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };
        let _shardsMinted: TypesICRC1.TransferResult = await shards.mint(_shardsArgs);

        switch (_shardsMinted) {
            case (#Ok(_tid)) {
                Debug.print("Shards minted successfully: " # Nat.toText(_tid));
            };
            case (#Err(_e)) {
                Debug.print("Error minting shards: ");
            };
        };
    };

    let fluxMinting = async {
        // Mint flux tokens
        let _fluxArgs: TypesICRC1.Mint = {
            to = { owner = caller; subaccount = null };
            amount = fluxAmount;
            memo = null;
            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };
        let _fluxMinted: TypesICRC1.TransferResult = await flux.mint(_fluxArgs);

        switch (_fluxMinted) {
            case (#Ok(_tid)) {
                Debug.print("Flux minted successfully: " # Nat.toText(_tid));
            };
            case (#Err(_e)) {
                Debug.print("Error minting flux:");
            };
        };
    };

    await shardsMinting;
    await fluxMinting;
};

// Function to get rarity from metadata
private func getRarityFromMetadata(metadata: [(Text, TypesICRC7.Metadata)]): Nat {
    for ((key, value) in metadata.vals()) {
        if (key == "rarity") {
            return switch (value) {
                case (#Nat(rarity)) rarity;
                case (_) 1;
            };
        };
    };
    return 1;
};

// Function to get token amounts based on rarity
private func getTokensAmount(rarity: Nat): (Nat, Nat) {
    var factor: Nat = 1;
    if (rarity <= 5) {
        factor := Nat.pow(2, rarity - 1);
    } else if (rarity <= 10) {
        factor := Nat.mul(Nat.pow(2, 5), Nat.div(Nat.pow(3, rarity - 6), Nat.pow(2, rarity - 6)));
    } else if (rarity <= 15) {
        factor := Nat.mul(Nat.mul(Nat.pow(2, 5), Nat.div(Nat.pow(3, 5), Nat.pow(2, 5))), Nat.div(Nat.pow(5, rarity - 11), Nat.pow(4, rarity - 11)));
    } else if (rarity <= 20) {
        factor := Nat.mul(Nat.mul(Nat.mul(Nat.pow(2, 5), Nat.div(Nat.pow(3, 5), Nat.pow(2, 5))), Nat.div(Nat.pow(5, 5), Nat.pow(4, 5))), Nat.div(Nat.pow(11, rarity - 16), Nat.pow(10, rarity - 16)));
    } else {
        factor := Nat.mul(Nat.mul(Nat.mul(Nat.mul(Nat.pow(2, 5), Nat.div(Nat.pow(3, 5), Nat.pow(2, 5))), Nat.div(Nat.pow(5, 5), Nat.pow(4, 5))), Nat.div(Nat.pow(11, 5), Nat.pow(10, 5))), Nat.div(Nat.pow(21, rarity - 21), Nat.pow(20, rarity - 21)));
    };
    let shardsAmount = Nat.mul(12, factor);
    let fluxAmount = Nat.mul(4, factor);
    return (shardsAmount, fluxAmount);
};



//async
public shared(msg) func openChests(chestID: Nat): async (Bool, Text) {
    // Perform ownership check
    let ownerof: TypesChests.OwnerResult = await chestsToken.icrc7_owner_of(chestID);
    let _owner: TypesChests.Account = switch (ownerof) {
        case (#Ok(owner)) owner;
        case (#Err(_)) return (false, "{\"success\":false, \"message\":\"Chest not found\"}");
    };

    if (Principal.notEqual(_owner.owner, msg.caller)) {
        return (false, "{\"success\":false, \"message\":\"Not the owner of the chest\"}");
    };

    // Immediate placeholder response to Unity
    let placeholderResponse = "{\"success\":true, \"message\":\"Chest opened successfully\", \"tokens\":[{\"token\":\"Shards\", \"amount\": 0}, {\"token\":\"Flux\", \"amount\": 0}]}";
    
    // Schedule background processing without waiting
    ignore _processChestContents(chestID, msg.caller);

    // Burn the chest token asynchronously without waiting for the result
    ignore async {
        let _chestArgs: TypesChests.OpenArgs = {
            from = _owner;
            token_id = chestID;
        };
        await chestsToken.openChest(_chestArgs);
    };

    return (true, placeholderResponse);
};

// Function to process chest contents in the background
private func _processChestContents(chestID: Nat, caller: Principal): async () {
    // Determine chest rarity based on metadata
    let metadataResult = await chestsToken.icrc7_metadata(chestID);
    let rarity = switch (metadataResult) {
        case (#Ok(metadata)) getRarityFromMetadata(metadata);
        case (#Err(_)) 1;
    };

    let (shardsAmount, fluxAmount) = getTokensAmount(rarity);

    // Mint tokens in parallel
    let shardsMinting = async {
        // Mint shards tokens
        let _shardsArgs: TypesICRC1.Mint = {
            to = { owner = caller; subaccount = null };
            amount = shardsAmount;
            memo = null;
            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };
        let _shardsMinted: TypesICRC1.TransferResult = await shardsToken.mint(_shardsArgs);

        switch (_shardsMinted) {
            case (#Ok(_tid)) {
                Debug.print("Shards minted successfully: " # Nat.toText(_tid));
            };
            case (#Err(_e)) {
                Debug.print("Error minting shards: " # errorToString(_e));
            };
        };
    };

    let fluxMinting = async {
        // Mint flux tokens
        let _fluxArgs: TypesICRC1.Mint = {
            to = { owner = caller; subaccount = null };
            amount = fluxAmount;
            memo = null;
            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };
        let _fluxMinted: TypesICRC1.TransferResult = await fluxToken.mint(_fluxArgs);

        switch (_fluxMinted) {
            case (#Ok(_tid)) {
                Debug.print("Flux minted successfully: " # Nat.toText(_tid));
            };
            case (#Err(_e)) {
                Debug.print("Error minting flux: " # errorToString(_e));
            };
        };
    };

    await shardsMinting;
    await fluxMinting;
};






// Mission helper queries

    public query func getActiveMissionIDs(user: Principal): async [Nat] {
        let now: Nat64 = Nat64.fromNat(Int.abs(Time.now()));

        Debug.print("[getActiveMissionIDs]Fetching active mission IDs for user: " # Principal.toText(user));
        var userRewards = switch (userProgress.get(user)) {
            case (null) { [] };
            case (?rewards) { rewards };
        };
        Debug.print("[getActiveMissionIDs]User rewards: " # debug_show(userRewards));

        var userClaimedMissions = switch (claimedMissions.get(user)) {
            case (null) { [] };
            case (?missions) { missions };
        };
        Debug.print("[getActiveMissionIDs]User claimed missions: " # debug_show(userClaimedMissions));

        let activeMissionIDs = Buffer.Buffer<Nat>(0);
        for (reward in userRewards.vals()) {
            if (not Utils.contains(userClaimedMissions, reward.id_reward, _natEqual) and reward.expiration >= now) {
                activeMissionIDs.add(reward.id_reward);
            }
        };

        return Buffer.toArray(activeMissionIDs);
    };

    // obtain claimed rewards for a user (NOTE: claimed rewards do not show any progress, only the ID)
    public query func getClaimedRewards(user: Principal): async [Nat] {
        var userClaimedMissions = switch (claimedMissions.get(user)) {
            case (null) { [] };
            case (?missions) { missions };
        };

        return userClaimedMissions;
    };









    // Query function to get all token IDs with their respective metadata
public query func getAllTokensWithMetadata() : async [(Types.TokenId, Types.TokenMetadata)] {
    let entries = Iter.toArray(Trie.iter(tokens));
    var result: [(Types.TokenId, Types.TokenMetadata)] = [];
    for (entry in entries.vals()) {
        let key = entry.0;
        let value = entry.1;
        result := Array.append(result, [(key, value)]);
    };
    return result;
};



Summary of Actions Tested by the Script
Player Registration Tests
Register a new player with a valid username and avatar.
Register multiple players with the same username but different principals.
Attempt to register a player with an invalid (too long) username.
Attempt to register a player with an empty username.
Update Tests
Update the username to a valid new username.
Attempt to update the username to an invalid (too long) username.
Update the avatar to a valid new avatar.
Update the description with a valid description.
Attempt to update the description with an invalid (too long) description.
Friend Request Tests
Attempt to send a friend request to oneself and ensure it fails.
Send a friend request to another player.
Attempt to send a duplicate friend request to the same user.
Attempt to send a friend request to a non-existent user.
Accept a friend request from another player.
Attempt to accept a non-existent friend request.
Verify that a friend request is not accepted until the other user accepts.
Ensure friend request shows up in the pending friend requests list.
Verify that blocked users cannot send friend requests.
Unblock a user and verify the process.
Blocking Tests
Attempt to block oneself and ensure it fails.
Block another player.
Attempt to block an already blocked user.
Test sending friend requests with different privacy settings (e.g., blockAll, acceptAll).
Privacy Setting Tests
Set an invalid privacy setting and ensure it fails.
Set the privacy setting to blockAll and verify it restricts friend requests.
Set the privacy setting to acceptAll and verify it allows friend requests.
Notification Tests
Verify that notifications are sent when privacy settings are updated.
Check the notifications list for a player.
Ensure old notifications are cleaned (conceptual, as time manipulation is not performed in the script).
Profile and Data Retrieval Tests
Retrieve a player's own profile.
Retrieve another player's profile.
Retrieve the full profile of another player, including stats and friends.
Search for a user by username and verify the results.
Get the list of all registered players.
General Robustness Tests
Simulate multiple simultaneous actions to test for concurrency issues.
Test the system's behavior under load by registering a large number of players and performing various operations.
New Players Introduced for Testing
player1
player2
player3
player4
player5
player6
Test Accounts and Principal IDs Retrieval
Retrieve and store the principal ID for each test account.
Comprehensive Summary
This testing script covers a wide range of scenarios including registration, updates, friend requests, blocking, privacy settings, notifications, profile retrieval, and general robustness. Each test is designed to ensure that the system handles various edge cases and typical usage scenarios correctly, providing thorough validation of the public functions.