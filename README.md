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