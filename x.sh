#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

commands=(
    "reset"
    "dfx identity use bizkit"
    "dfx canister uninstall-code cosmicrafts"
    "dfx deploy cosmicrafts"
    "dfx canister call cosmicrafts adminManagement '(variant { CreateMissionsPeriodically })'"
   # "python scripts/missions.py"
)

for command in "${commands[@]}"; do
    echo "Executing: $command"
    eval $command
    echo "Command executed successfully."
done

# Inline expect script for registerPlayer.py
expect <<EOF
    set timeout -1
    spawn python scripts/registerPlayer.py
    expect "Enter the number of users to register: "
    send "2\r"
    expect eof
EOF

# Inline expect script for matchmaking.py
expect <<EOF
    set timeout -1
    spawn python scripts/matchmaking.py
    expect "Enter the number of matches to run: "
    send "1\r"
    expect "Do you want to loop indefinitely? (y/n): "
    send "n\r"
    expect eof
EOF

# Inline expect script for claimRewards.py
expect <<EOF
    set timeout -1
    spawn python scripts/claimRewards.py
    expect eof
EOF

echo "All commands executed successfully."
