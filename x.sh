#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

commands=(
    "reset"
    "dfx identity use default"
    "dfx canister uninstall-code cosmicrafts"
    "dfx deploy"
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
    send "20\r"
    expect eof
EOF

# Inline expect script for matchmaking.py
expect <<EOF
    set timeout -1
    spawn python scripts/matchmaking.py
    expect "Enter the number of matches to run: "
    send "10\r"
    expect "Do you want to loop indefinitely? (y/n): "
    send "y\r"
    expect eof
EOF

echo "All commands executed successfully."
