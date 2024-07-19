# `cosmicrafts`

dfx deploy cxp --ic --argument '( record { name = "Cosmicrafts XP"; symbol = "CXP"; decimals = 8; fee = 1; max_supply = 1_000_000_000_000_000_000_000_000; initial_balances = vec {
record { record { owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null; }; 100_000_000_000 } }; min_burn_amount = 1; minting_account = opt record { owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null; }; advanced_settings = null; })'

dfx deploy energy --ic --argument '( record { name = "Cosmicrafts Energy"; symbol = "NRG"; decimals = 8; fee = 1; max_supply = 1_000_000_000_000_000_000_000_000; initial_balances = vec {
record { record { owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null; }; 100_000_000_000 } }; min_burn_amount = 1; minting_account = opt record { owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null; }; advanced_settings = null; })'


dfx canister uninstall-code etqmj-zyaaa-aaaap-aakaq-cai --ic
dfx canister uninstall-code b7g3n-niaaa-aaaaj-aadlq-cai --ic

dfx canister call etqmj-zyaaa-aaaap-aakaq-cai mint --ic
dfx canister call b7g3n-niaaa-aaaaj-aadlq-cai mint --ic

gccov-gnjwn-heylh-mzo3a-kdpre-vs75x-aa353-ixynu-qkmgn-l36pm-cae


dfx deploy icrc7 --argument '( record {owner = principal "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"; subaccount = null;}, record { "name" = "Cosmicrafts Avatars"; symbol = "CSA"; royalties = null; royaltyRecipient = null; description = null; image = null; supplyCap = null; })'


Missing
getUserRewards 



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