import subprocess
import random
import string

def generate_random_name(length=8):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

# Prompt the user for the number of players to register
num_players = int(input("How many players would you like to register? "))

# Generate random usernames
usernames = [generate_random_name() for _ in range(num_players)]

for i in range(1, num_players + 1):
    identity_name = f"player{i}"
    
    # Check if identity already exists
    result = subprocess.run(["dfx", "identity", "list"], capture_output=True, text=True)
    
    if identity_name not in result.stdout:
        # Create a new identity if it doesn't exist
        subprocess.run(["dfx", "identity", "new", identity_name], check=True)
    
    # Switch to the new or existing identity
    subprocess.run(["dfx", "identity", "use", identity_name], check=True)
    
    # Call the createPlayer function with the generated username
    username = usernames[i-1]
    create_player_command = f'dfx canister call cosmicrafts createPlayer \'("{username}")\''
    subprocess.run(create_player_command, shell=True, check=True)

print(f"{num_players} players created successfully.")
