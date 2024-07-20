import subprocess
import re

# Define the initial commands to be executed
commands = [
    "dfx identity use player1",
    "dfx canister call cosmicrafts claimReward '(1 : nat)'",
    "dfx canister call cosmicrafts claimReward '(2 : nat)'",
    "dfx canister call cosmicrafts claimReward '(3 : nat)'"
]

# Execute the commands sequentially and capture the output of the last claimReward command
uuid = None
for command in commands:
    print(f"Executing: {command}")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        print(result.stdout)
        if "Chest minted and reward claimed" in result.stdout:
            # Extract the UUID from the output using regex
            match = re.search(r"UUID: (\d+)", result.stdout)
            if match:
                uuid = match.group(1)
    else:
        print(f"Error executing {command}: {result.stderr}")

if uuid:
    # Use the extracted UUID for the openChest command
    open_chest_command = f"dfx canister call cosmicrafts openChest '({uuid} : nat)'"
    print(f"Executing: {open_chest_command}")
    result = subprocess.run(open_chest_command, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        print(result.stdout)
    else:
        print(f"Error executing {open_chest_command}: {result.stderr}")
else:
    print("Failed to extract UUID from claimReward command output.")

print("All commands executed.")
