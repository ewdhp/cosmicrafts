#!/bin/bash

#start
dfx start --background

#create canisters
#dfx canister create --all

# Install icrc7 canister
dfx deploy icrc7 --argument '( record {owner = principal "bd3sg-teaaa-aaaaa-qaaba-cai"; subaccount = null;}, record { "name" = "Cosmicrafts Game NFTs"; symbol = "CS"; royalties = null; royaltyRecipient = null; description = null; image = null; supplyCap = null; })' --mode=reinstall

# Install chests canister
dfx deploy chests --argument '( record {owner = principal "bd3sg-teaaa-aaaaa-qaaba-cai"; subaccount = null;}, record { "name" = "Cosmicrafts Game NFTs"; symbol = "CS"; royalties = null; royaltyRecipient = null; description = null; image = null; supplyCap = null; })' --mode=reinstall

# Install icrc1 canister
dfx deploy icrc1 --argument '( record { name = "Shards"; symbol = "SHRD"; decimals = 0; fee = 1; max_supply = 1_000_000_000_000_000; initial_balances = vec { record { record { owner = principal "bd3sg-teaaa-aaaaa-qaaba-cai"; subaccount = null; }; 100_000_000_000 } }; min_burn_amount = 1; minting_account = opt record { owner = principal "bd3sg-teaaa-aaaaa-qaaba-cai"; subaccount = null; }; advanced_settings = null; })' --mode=reinstall

# Install flux canister
dfx deploy flux --argument '( record { name = "Flux"; symbol = "FLUX"; decimals = 0; fee = 1; max_supply = 1_000_000_000_000_000; initial_balances = vec { record { record { owner = principal "bd3sg-teaaa-aaaaa-qaaba-cai"; subaccount = null; }; 100_000_000_000 } }; min_burn_amount = 1; minting_account = opt record { owner = principal "bd3sg-teaaa-aaaaa-qaaba-cai"; subaccount = null; }; advanced_settings = null; })' --mode=reinstall

# Install cosmicrafts canister
dfx deploy cosmicrafts

echo "All canisters installed successfully."
