import subprocess
import logging
import random
import string

# Set up logging
logging.basicConfig(filename='logs/register_users.log', level=logging.INFO, format='%(asctime)s - %(message)s')

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

def generate_random_username(length=12):
    """Generates a random username with a specified length."""
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

def register_user(identity_name, username, avatar_id):
    """Registers a user using the registerUser canister method."""
    command = f'dfx canister call cosmicrafts registerUser \'("{username}", {avatar_id})\''
    return execute_dfx_command(command)

def main():
    """Main function to register users."""
    num_users = int(input("Enter the number of users to register: "))

    users = [f"player{i}" for i in range(1, num_users + 1)]  # Create player identities

    # Register each user
    for user in users:
        try:
            print(f"Switching to identity {user}\n")
            logging.info(f"Switching to identity {user}")
            switch_identity(user)
            username = generate_random_username()
            avatar_id = random.randint(1, 33)
            try:
                register_user(user, username, avatar_id)
            except Exception as e:
                error_message = f"Error registering {user} with username {username} and avatar ID {avatar_id}: {e}"
                print(error_message)
                logging.error(error_message)
        except Exception as e:
            error_message = f"Error switching identity for {user}: {e}"
            print(error_message)
            logging.error(error_message)

if __name__ == "__main__":
    main()
