#!/bin/bash

#start
dfx identity use bizkit
dfx stop
dfx start --background --clean

#create canisters
#dfx canister create --all

# Install cosmicrafts canister
dfx deploy cosmicrafts

# Install gamenfts canister
dfx deploy gamenfts --argument '( record {owner = principal "bkyz2-fmaaa-aaaaa-qaaaq-cai"; subaccount = null;}, record { "name" = "Cosmicrafts Game NFTs"; symbol = "CS"; royalties = null; royaltyRecipient = null; description = null; image = null; supplyCap = null; })'

# Install chests canister
dfx deploy chests --argument '( record {owner = principal "bkyz2-fmaaa-aaaaa-qaaaq-cai"; subaccount = null;}, record { "name" = "Cosmicrafts Game NFTs"; symbol = "CS"; royalties = null; royaltyRecipient = null; description = null; image = null; supplyCap = null; })'

# Install shards token
dfx deploy shards --argument '( record { name = "Shards"; symbol = "SHRD"; decimals = 8; fee = 1; max_supply = 1_000_000_000_000_000; initial_balances = vec { record { record { owner = principal "bkyz2-fmaaa-aaaaa-qaaaq-cai"; subaccount = null; }; 100_000_000_000 } }; min_burn_amount = 1; minting_account = opt record { owner = principal "bkyz2-fmaaa-aaaaa-qaaaq-cai"; subaccount = null; }; advanced_settings = null; })'

# Install flux token
dfx deploy flux --argument '( record { name = "Flux"; symbol = "FLUX"; decimals = 8; fee = 1; max_supply = 1_000_000_000_000_000; initial_balances = vec { record { record { owner = principal "bkyz2-fmaaa-aaaaa-qaaaq-cai"; subaccount = null; }; 100_000_000_000 } }; min_burn_amount = 1; minting_account = opt record { owner = principal "bkyz2-fmaaa-aaaaa-qaaaq-cai"; subaccount = null; }; advanced_settings = null; })'

echo "All canisters installed successfully."