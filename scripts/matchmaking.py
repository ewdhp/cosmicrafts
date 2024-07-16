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
    for attempt in range(3):  # Retry up to 3 times
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
            if attempt < 2:  # Only retry if not the last attempt
                logging.info("Retrying...")
                time.sleep(1)
            else:
                raise Exception(error_message)  # Raise an exception to halt on error
    return None

def switch_identity(identity_name):
    """Switches the DFX identity using a lock to prevent race conditions."""
    with identity_lock:
        execute_dfx_command(f"dfx identity use {identity_name}", log_output=False)
        for _ in range(5):  # Try up to 5 times
            current_identity = execute_dfx_command("dfx identity whoami", log_output=False)
            if current_identity == identity_name:
                return
            time.sleep(0.5)  # Wait for 0.5 seconds before checking again
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

def is_game_matched(identity_name, retries=10):
    """Checks if the game is matched with a maximum number of retries."""
    switch_identity(identity_name)
    for _ in range(retries):
        result = execute_dfx_command('dfx canister call cosmicrafts isGameMatched')
        if "true" in result:
            return result
        time.sleep(1)  # Wait before retrying
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
        player1, player2 = match_queue.get()
        if player1 is None and player2 is None:
            break  # Exit signal
        process_match(player1, player2)
        match_queue.task_done()

def process_match(player1, player2):
    """Processes a single match between two players."""
    player_game_data = {
        "userAvatar": 1,  # Replace with actual avatar ID
        "listSavedKeys": []  # Replace with actual saved keys if needed
    }

    # Start searching for a match for both players
    print(f"{player1} starts searching for a match")
    logging.info(f"{player1} starts searching for a match")
    search_result1 = get_match_searching(player1, player_game_data)
    print(f"{player1} search result: {search_result1}")
    logging.info(f"{player1} search result: {search_result1}")
    match_id1 = parse_match_id(search_result1)

    print(f"{player2} starts searching for a match")
    logging.info(f"{player2} starts searching for a match")
    search_result2 = get_match_searching(player2, player_game_data)
    print(f"{player2} search result: {search_result2}")
    logging.info(f"{player2} search result: {search_result2}")
    match_id2 = parse_match_id(search_result2)

    # Wait until both players confirm the match
    player1_matched = False
    player2_matched = False

    while not (player1_matched and player2_matched):
        is_matched_result1 = is_game_matched(player1)
        is_matched_result2 = is_game_matched(player2)
        print_match_status(player1, is_matched_result1)
        print_match_status(player2, is_matched_result2)

        player1_matched = "true" in is_matched_result1
        player2_matched = "true" in is_matched_result2

        if not (player1_matched and player2_matched):
            print("Waiting for both players to be matched...")
            logging.info("Waiting for both players to be matched...")
            time.sleep(1)

    print("Match found! Ending search.")
    logging.info("Match found! Ending search.")

    # Confirm both players are in the same match
    match_data_player1 = get_my_match_data(player1)
    match_data_player2 = get_my_match_data(player2)
    print(f"Match data for {player1}: {match_data_player1}")
    print(f"Match data for {player2}: {match_data_player2}")
    logging.info(f"Match data for {player1}: {match_data_player1}")
    logging.info(f"Match data for {player2}: {match_data_player2}")

    # Send statistics immediately for the matched players
    shared_energy_generated = random.randint(50, 210)
    shared_sec_remaining = random.randint(30, 300)
    won = random.choice([True, False])

    for player, match_id in [(player1, match_id1), (player2, match_id2)]:
        print(f"Sending statistics for match ID: {match_id} for {player}")
        logging.info(f"Sending statistics for match ID: {match_id} for {player}")

        stats = generate_random_stats(shared_energy_generated, shared_sec_remaining, won, get_principal(player))

        try:
            save_finished_game(player, match_id, stats)
        except Exception as e:
            print(f"Error saving statistics for {player} in match {match_id}: {e}")
            logging.error(f"Error saving statistics for {player} in match {match_id}: {e}")
            return  # Halt on error

    # Verify the basic stats after sending stats
    for player, match_id in [(player1, match_id1), (player2, match_id2)]:
        basic_stats = get_basic_stats(player, match_id)
        print(f"Basic stats for match ID {match_id} after sending stats: {basic_stats}")
        logging.info(f"Basic stats for match ID {match_id} after sending stats: {basic_stats}")

def run_matches(num_matches):
    """Run the specified number of matches."""
    num_players = num_matches * 2  # Each match requires 2 players

    players = [f"player{i}" for i in range(1, num_players + 1)]  # Create player identities

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

    # Add matches to the queue
    for i in range(0, num_players, 2):
        match_queue.put((players[i], players[i + 1]))

    # Wait for all matches to be processed
    match_queue.join()

    # Stop worker threads
    for _ in range(num_workers):
        match_queue.put((None, None))
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
