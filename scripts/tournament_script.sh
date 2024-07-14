#!/bin/bash

# Set the canister ID and network
CANISTER_ID="lqaq5-paaaa-aaaap-qhndq-cai"
NETWORK="ic"

# Define identities
ADMIN_IDENTITY="bizkit"
IDENTITIES=("player1" "player2" "player3" "player4" "player5" "player6" "player7" "player8")
declare -A PRINCIPALS

# Create a tournament and capture the tournament ID
echo "Creating a tournament..."
TOURNAMENT_ID=$(dfx canister --network $NETWORK call $CANISTER_ID createTournament '("Test Tournament", 1625151600000, "100 ICP", 1627730000000)' | grep -oP '(?<=\().*?(?=\ : nat\))')

# Check if the tournament was created successfully
if [ -z "$TOURNAMENT_ID" ]; then
  echo "Failed to create tournament."
  exit 1
fi

echo "Created tournament with ID: $TOURNAMENT_ID"

# Join tournament with different identities and fetch their principals
echo "Joining tournament with different identities..."
for identity in "${IDENTITIES[@]}"; do
  dfx identity use $identity
  echo "Using identity: \"$identity\" to join tournament."
  JOIN_RESULT=$(dfx canister --network $NETWORK call $CANISTER_ID joinTournament "($TOURNAMENT_ID)")
  echo "Join result for $identity: $JOIN_RESULT"
  PRINCIPAL=$(dfx identity get-principal | grep -oP '(?<=Principal\s\").*?(?=\")')
  PRINCIPALS[$identity]=$PRINCIPAL
  echo "Principal for $identity: $PRINCIPAL"
done

# Switch to admin identity and update the bracket
echo "Updating bracket as admin..."
dfx identity use $ADMIN_IDENTITY
BRACKET_UPDATE_RESULT=$(dfx canister --network $NETWORK call $CANISTER_ID updateBracket "($TOURNAMENT_ID)")
echo "Bracket update result: $BRACKET_UPDATE_RESULT"

# Function to fetch and parse the tournament bracket
fetch_and_parse_bracket() {
  TOURNAMENT_BRACKET=$(dfx canister --network $NETWORK call $CANISTER_ID getTournamentBracket "($TOURNAMENT_ID)")
  echo "Updated tournament bracket: $TOURNAMENT_BRACKET"

  MATCH_PARTICIPANTS=()
  MATCH_IDS=($(echo "$TOURNAMENT_BRACKET" | grep -oP '(?<=id = )\d+'))
  MATCH_PARTICIPANT_BLOCKS=($(echo "$TOURNAMENT_BRACKET" | grep -oP '(?<=participants = vec \{).*?(?=\};)'))
  for (( i=0; i<${#MATCH_IDS[@]}; i++ )); do
    PARTICIPANTS=$(echo "${MATCH_PARTICIPANT_BLOCKS[$i]}" | sed 's/, / /g')
    MATCH_PARTICIPANTS[$i]=$PARTICIPANTS
    echo "Match ${MATCH_IDS[$i]} participants: $PARTICIPANTS"
  done
}

# Fetch the initial bracket
fetch_and_parse_bracket

# Switch to admin identity to verify and update matches
echo "Verifying and updating matches as admin..."
dfx identity use $ADMIN_IDENTITY
for match_id in "${MATCH_IDS[@]}"; do
  ADMIN_UPDATE_RESULT=$(dfx canister --network $NETWORK call $CANISTER_ID adminUpdateMatch "($match_id, \"3-2\")")
  echo "Admin update result for match $match_id: $ADMIN_UPDATE_RESULT"
done

# Fetch and display the tournament bracket after the first round
echo "Fetching the tournament bracket after the first round..."
fetch_and_parse_bracket

# Finalize the tournament if necessary
if [ ${#MATCH_IDS[@]} -eq 1 ]; then
  echo "Finalizing the tournament..."
  FINALIZE_RESULT=$(dfx canister --network $NETWORK call $CANISTER_ID adminUpdateMatch "(0, \"3-2\")")
  echo "Finalization result: $FINALIZE_RESULT"
  FINAL_BRACKET=$(dfx canister --network $NETWORK call $CANISTER_ID getTournamentBracket "($TOURNAMENT_ID)")
  echo "Final tournament bracket: $FINAL_BRACKET"
fi

echo "Tournament process complete."
