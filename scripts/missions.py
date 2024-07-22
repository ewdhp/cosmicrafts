import subprocess
import logging
import time
import signal
import sys

# Set up logging
#logging.basicConfig(filename='logs/missions.log', level=logging.INFO, format='%(asctime)s - %(message)s')

def execute_dfx_command(command, log_output=True):
    """Executes a shell command and logs the output."""
    for attempt in range(3):  # Retry up to 3 times
        result = subprocess.run(command, capture_output=True, text=True, shell=True)
        if result.returncode == 0:
            output = result.stdout.strip()
            if log_output:
                logging.info(f"Command: {command}")
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

def create_mission(mission_name, reward_type):
    """Creates a mission with the specified arguments."""
    mission_type = 'variant { "GamesCompleted" }'
    reward_variant = f'variant {{ "{reward_type}" }}'
    nat_value = 1
    nat64_value = 1
    command = f'dfx canister call cosmicrafts createMission \'("{mission_name}", {mission_type}, {reward_variant}, {nat_value}, {nat_value}, {nat64_value})\''
    return execute_dfx_command(command)

def run_missions():
    """Run the mission creation process."""
    missions = [
        ("Complete 1 Game for Flux", "Flux"),
        ("Complete 1 Game for Shards", "Shards"),
        ("Complete 1 Game for Chest", "Chest"),
    ]

    for mission_name, reward_type in missions:
        try:
            logging.info(f"Creating mission: {mission_name} with reward type: {reward_type}")
            result = create_mission(mission_name, reward_type)
            logging.info(f"Mission creation result: {result}")
            print(f"Mission created: {mission_name} with reward type: {reward_type}\nResult: {result}")
        except Exception as e:
            error_message = f"Error creating mission {mission_name} with reward type {reward_type}: {e}"
            logging.error(error_message)
            print(error_message)
            return  # Halt on error

if __name__ == "__main__":
    def exit_gracefully(signum, frame):
        """Handle graceful exit on Ctrl+C or termination signal."""
        print("Exiting gracefully...")
        sys.exit(0)

    signal.signal(signal.SIGINT, exit_gracefully)
    signal.signal(signal.SIGTERM, exit_gracefully)

    try:
        run_missions()
    except Exception as e:
        logging.error(f"Exception occurred: {e}")
