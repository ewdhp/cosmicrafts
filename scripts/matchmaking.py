import subprocess
import json
import logging
import re
import random
import time

# Set up logging
logging.basicConfig(filename='logs/matchmaking.log', level=logging.INFO, format='%(asctime)s - %(message)s')

def execute_dfx_command(command, log_output=True):
    """Executes a shell command and logs the output."""
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    if result.returncode != 0:
        error_message = f"Command failed: {command}\n{result.stderr.strip()}"
        print(error_message)
        logging.error(error_message)
        raise Exception(error_message)  # Raise an exception to halt on error
    else:
        output = result.stdout.strip()
        print(f"Command: {command}")
        logging.info(f"Command: {command}")
        if log_output:
            print(f"Output: {output}\n")
            logging.info(f"Output: {output}")
    return output

def switch_identity(identity_name):
    """Switches the DFX identity."""
    execute_dfx_command(f"dfx identity use {identity_name}", log_output=False)

def get_principal(identity_name):
    """Gets the principal of the current identity."""
    switch_identity(identity_name)
    principal = execute_dfx_command("dfx identity get-principal")
    return principal

def get_match_searching(identity_name, player_game_data):
    """Starts searching for a match."""
    switch_identity(identity_name)
    player_game_data_str = json.dumps(player_game_data)
    command = f'dfx canister call cosmicrafts getMatchSearching \'{player_game_data_str}\''
    return execute_dfx_command(command)

def set_player_active(identity_name):
    """Sets the player as active."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts setPlayerActive'
    return execute_dfx_command(command)

def is_game_matched(identity_name):
    """Checks if the game is matched."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts isGameMatched'
    return execute_dfx_command(command)

def save_finished_game(identity_name, game_id, stats):
    """Saves the finished game statistics."""
    switch_identity(identity_name)

    stats_str = (
        'record {'
        f'botDifficulty = {stats["botDifficulty"]}; '
        f'botMode = {stats["botMode"]}; '
        f'characterID = "{stats["characterID"]}"; '
        f'damageCritic = {stats["damageCritic"]}; '
        f'damageDealt = {stats["damageDealt"]}; '
        f'damageEvaded = {stats["damageEvaded"]}; '
        f'damageTaken = {stats["damageTaken"]}; '
        f'deploys = {stats["deploys"]}; '
        f'energyChargeRate = {stats["energyChargeRate"]}; '
        f'energyGenerated = {stats["energyGenerated"]}; '
        f'energyUsed = {stats["energyUsed"]}; '
        f'energyWasted = {stats["energyWasted"]}; '
        f'faction = {stats["faction"]}; '
        f'gameMode = {stats["gameMode"]}; '
        f'kills = {stats["kills"]}; '
        f'secRemaining = {stats["secRemaining"]}; '
        f'wonGame = {str(stats["wonGame"]).lower()}; '
        f'xpEarned = {stats["xpEarned"]}; '
        '}'
    )

    command = (
        f'dfx canister call cosmicrafts saveFinishedGame \'({game_id}, {stats_str})\''
    )
    print(f"Constructed command: {command}")
    logging.info(f"Constructed command: {command}")
    return execute_dfx_command(command)

def parse_match_id(search_result):
    """Extracts the match ID from the search result."""
    match = re.search(r'\(variant \{ Assigned \}, (\d+) : nat,', search_result)
    if match:
        return int(match.group(1))
    else:
        raise ValueError("Match ID not found in the search result")

def generate_random_stats(shared_energy_generated, shared_sec_remaining, won):
    """Generates randomized game statistics."""
    stats = {
        "botDifficulty": random.randint(0, 5),
        "botMode": random.randint(0, 5),
        "characterID": f"character{random.randint(1, 10)}",
        "damageCritic": random.uniform(1000, 25000),
        "damageDealt": random.uniform(1000, 25000),
        "damageEvaded": random.uniform(1000, 25000),
        "damageTaken": random.uniform(1000, 25000),
        "deploys": random.uniform(10, 225),
        "energyChargeRate": random.uniform(33, 200),
        "energyGenerated": float(shared_energy_generated),
        "energyUsed": random.uniform(33, 200),
        "energyWasted": random.uniform(33, 200),
        "faction": random.randint(0, 5),
        "gameMode": random.randint(0, 5),
        "kills": random.uniform(10, 250),
        "secRemaining": float(shared_sec_remaining),
        "wonGame": won,
        "xpEarned": random.uniform(1000, 25000)
    }
    return stats

def run_matches(num_matches):
    """Run the specified number of matches."""
    num_players = num_matches * 2  # Each match requires 2 players

    players = [f"player{i}" for i in range(1, num_players + 1)]  # Create player identities

    while True:
        # Shuffle the players
        random.shuffle(players)

        # Get principals for all players
        principals = {player: get_principal(player) for player in players}

        player_game_data = {
            "userAvatar": 1,  # Replace with actual avatar ID
            "listSavedKeys": []  # Replace with actual saved keys if needed
        }

        match_ids = []

        for i in range(0, num_players, 2):  # Iterate in steps of 2 for pairs of players
            player1 = players[i]
            player2 = players[i + 1]

            # Start searching for a match for player1
            print(f"{player1} starts searching for a match")
            logging.info(f"{player1} starts searching for a match")
            search_result1 = get_match_searching(player1, player_game_data)
            print(f"{player1} search result: {search_result1}")
            logging.info(f"{player1} search result: {search_result1}")
            match_id1 = parse_match_id(search_result1)
            match_ids.append((player1, match_id1))

            # Simulate player1 activation and match confirmation
            active_result1 = set_player_active(player1)
            print(f"{player1} active result: {active_result1}")
            logging.info(f"{player1} active result: {active_result1}")

            # Start searching for a match for player2
            print(f"{player2} starts searching for a match")
            logging.info(f"{player2} starts searching for a match")
            search_result2 = get_match_searching(player2, player_game_data)
            print(f"{player2} search result: {search_result2}")
            logging.info(f"{player2} search result: {search_result2}")
            match_id2 = parse_match_id(search_result2)
            match_ids.append((player2, match_id2))

            # Simulate player2 activation and match confirmation
            active_result2 = set_player_active(player2)
            print(f"{player2} active result: {active_result2}")
            logging.info(f"{player2} active result: {active_result2}")

            # Wait until both players confirm the match
            player1_matched = False
            player2_matched = False

            while not (player1_matched and player2_matched):
                is_matched_result1 = is_game_matched(player1)
                is_matched_result2 = is_game_matched(player2)
                print(f"Is game matched result for {player1}: {is_matched_result1}")
                logging.info(f"Is game matched result for {player1}: {is_matched_result1}")
                print(f"Is game matched result for {player2}: {is_matched_result2}")
                logging.info(f"Is game matched result for {player2}: {is_matched_result2}")

                player1_matched = "true" in is_matched_result1
                player2_matched = "true" in is_matched_result2

                if not (player1_matched and player2_matched):
                    print("Waiting for both players to be matched...")
                    logging.info("Waiting for both players to be matched...")

            print("Match found! Ending search.")
            logging.info("Match found! Ending search.")

            # Send statistics immediately for the matched players
            shared_energy_generated = random.randint(50, 210)
            shared_sec_remaining = random.randint(30, 300)
            won = random.choice([True, False])

            for player, match_id in [(player1, match_id1), (player2, match_id2)]:
                print(f"Sending statistics for match ID: {match_id} for {player}")
                logging.info(f"Sending statistics for match ID: {match_id} for {player}")

                stats = generate_random_stats(shared_energy_generated, shared_sec_remaining, won)

                try:
                    save_finished_game(player, match_id, stats)
                except Exception as e:
                    print(f"Error saving statistics for {player} in match {match_id}: {e}")
                    logging.error(f"Error saving statistics for {player} in match {match_id}: {e}")
                    return  # Halt on error

            match_ids.clear()  # Clear match IDs after saving stats

        print(f"Finished {num_matches} matches. Looping..." if loop else "Finished {num_matches} matches.")
        logging.info(f"Finished {num_matches} matches. Looping..." if loop else "Finished {num_matches} matches.")

        if not loop:
            break

        time.sleep(5)  # Add a delay before starting the next loop, if desired

if __name__ == "__main__":
    num_matches = int(input("Enter the number of matches to run: "))
    loop = input("Do you want to loop indefinitely? (yes/no): ").strip().lower() == "yes"
    run_matches(num_matches)
