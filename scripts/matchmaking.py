import subprocess
import json
import logging
import re
import random
import time
import sys
import signal
from queue import Queue
from threading import Thread, Lock

# Set up logging
logging.basicConfig(filename='logs/matchmaking.log', level=logging.INFO, format='%(asctime)s - %(message)s')

identity_lock = Lock()

def execute_dfx_command(command, log_output=True):
    """Executes a shell command and logs the output."""
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    if result.returncode == 0:
        output = result.stdout.strip()
        print(f"Command: {command}")
        logging.info(f"Command: {command}")
        if log_output:
            print(f"Output: {output}\n")
            logging.info(f"Output: {output}")
        return output
    else:
        error_message = f"Command failed: {command}\n{result.stderr.strip()}"
        logging.error(error_message)
        raise Exception(error_message)  # Raise an exception to halt on error

def switch_identity(identity_name):
    """Switches the DFX identity using a lock to prevent race conditions."""
    with identity_lock:
        execute_dfx_command(f"dfx identity use {identity_name}", log_output=False)
        current_identity = execute_dfx_command("dfx identity whoami", log_output=False)
        if current_identity != identity_name:
            raise Exception(f"Failed to switch identity to {identity_name}")

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

def is_game_matched(identity_name):
    """Checks if the game is matched."""
    switch_identity(identity_name)
    result = execute_dfx_command('dfx canister call cosmicrafts isGameMatched')
    return result

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
        f'playerId = principal "{stats["playerId"]}"; '
        '}'
    )
    command = (
        f'dfx canister call cosmicrafts saveFinishedGame \'({game_id}, {stats_str})\''
    )
    print(f"Constructed command: {command}")
    logging.info(f"Constructed command: {command}")
    return execute_dfx_command(command)

def get_basic_stats(identity_name, match_id):
    """Gets basic stats for the specified match ID."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts getBasicStats {match_id}'
    return execute_dfx_command(command)

def get_my_match_data(identity_name):
    """Gets match data for the current player."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts getMyMatchData'
    return execute_dfx_command(command)

def parse_match_id(search_result):
    """Extracts the match ID from the search result."""
    match = re.search(r'\(variant \{ Assigned \}, (\d+) : nat,', search_result)
    if match:
        return int(match.group(1))
    else:
        raise ValueError("Match ID not found in the search result")

def generate_random_stats(shared_energy_generated, shared_sec_remaining, won, player_id):
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
        "xpEarned": random.uniform(1000, 25000),
        "playerId": player_id
    }
    return stats

def print_match_status(player, status):
    print(f"{player} match status: {status}")
    logging.info(f"{player} match status: {status}")

def match_worker():
    while True:
        player = match_queue.get()
        if player is None:
            break  # Exit signal
        process_match(player)
        match_queue.task_done()

def search_and_match(player):
    player_game_data = {
        "userAvatar": 1,  # Replace with actual avatar ID
        "listSavedKeys": []  # Replace with actual saved keys if needed
    }
    search_result = get_match_searching(player, player_game_data)
    print(f"{player} search result: {search_result}")
    logging.info(f"{player} search result: {search_result}")
    match_id = parse_match_id(search_result)
    
    for _ in range(3):  # Try to confirm match up to 3 times
        is_matched_result = is_game_matched(player)
        print_match_status(player, is_matched_result)
        if "true" in is_matched_result:
            return match_id
        else:
            time.sleep(1)
            search_result = get_match_searching(player, player_game_data)
            match_id = parse_match_id(search_result)
    raise Exception(f"{player} did not find a match after 3 attempts.")

def process_match(player):
    """Processes a single match for a player."""
    try:
        match_id = search_and_match(player)
        match_data = get_my_match_data(player)
        print(f"Match data for {player}: {match_data}")
        logging.info(f"Match data for {player}: {match_data}")

        if match_data:
            # Simulate sending statistics
            shared_energy_generated = random.randint(50, 210)
            shared_sec_remaining = random.randint(30, 300)
            won = random.choice([True, False])
            stats = generate_random_stats(shared_energy_generated, shared_sec_remaining, won, get_principal(player))
            save_finished_game(player, match_id, stats)
        else:
            print(f"Error: {player} did not find a match. Retrying search...")
            logging.info(f"Error: {player} did not find a match. Retrying search...")
            search_and_match(player)
    except Exception as e:
        print(f"Error processing match for {player}: {e}")
        logging.error(f"Error processing match for {player}: {e}")

def run_matches(num_matches):
    """Run the specified number of matches."""
    players = [f"player{i}" for i in range(1, num_matches + 1)]  # Create player identities

    # Initialize the match queue
    global match_queue
    match_queue = Queue()

    # Start worker threads
    num_workers = 4
    threads = []
    for _ in range(num_workers):
        t = Thread(target=match_worker)
        t.start()
        threads.append(t)

    # Add players to the queue
    for player in players:
        match_queue.put(player)

    # Wait for all matches to be processed
    match_queue.join()

    # Stop worker threads
    for _ in range(num_workers):
        match_queue.put(None)
    for t in threads:
        t.join()

    print(f"Finished {num_matches} matches.")
    logging.info(f"Finished {num_matches} matches.")

if __name__ == "__main__":
    def exit_gracefully(signum, frame):
        """Handle graceful exit on Ctrl+C or termination signal."""
        switch_identity("default")
        print("Exiting gracefully...")
        sys.exit(0)

    signal.signal(signal.SIGINT, exit_gracefully)
    signal.signal(signal.SIGTERM, exit_gracefully)

    try:
        num_matches = int(input("Enter the number of matches to run: "))
        loop = input("Do you want to loop indefinitely? (yes/no): ").strip().lower() == "yes"
        while loop:
            run_matches(num_matches)
    finally:
        switch_identity("default")
