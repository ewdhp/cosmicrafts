#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

commands=(
    "reset"
    "dfx identity use default"
    "dfx canister uninstall-code cosmicrafts"
    "dfx deploy"
    "python scripts/registerPlayer.py"
)

for command in "${commands[@]}"; do
    echo "Executing: $command"
    eval $command
    echo "Command executed successfully."
done

echo "All commands executed successfully."
