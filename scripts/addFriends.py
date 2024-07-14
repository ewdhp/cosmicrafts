import subprocess
import logging

# Set up logging
logging.basicConfig(filename='logs/add_friends.log', level=logging.INFO, format='%(asctime)s - %(message)s')

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

def add_friend(identity_name, friend_principal):
    """Adds a friend using the addFriend canister method."""
    command = f'dfx canister call cosmicrafts addFriend "(principal \\"{friend_principal}\\")"'
    return execute_dfx_command(command)

def main():
    """Main function to add friends to each other."""
    num_friends = int(input("Enter the number of friends to add: "))

    friends = [f"player{i}" for i in range(1, num_friends + 1)]  # Create player identities

    # Get principals for all friends
    principals = {friend: get_principal(friend) for friend in friends}

    # Add each friend to each other
    for friend in friends:
        try:
            print(f"Switching to identity {friend}\n")
            logging.info(f"Switching to identity {friend}")
            switch_identity(friend)
            for other_friend, principal in principals.items():
                if friend != other_friend:  # Exclude itself
                    try:
                        add_friend(friend, principal)
                    except Exception as e:
                        error_message = f"Error adding {other_friend} for {friend}: {e}"
                        print(error_message)
                        logging.error(error_message)
        except Exception as e:
            error_message = f"Error switching identity or getting principal for {friend}: {e}"
            print(error_message)
            logging.error(error_message)

if __name__ == "__main__":
    main()
