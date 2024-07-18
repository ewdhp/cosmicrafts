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
