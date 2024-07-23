import subprocess
import logging
import sys

# Set up logging
logging.basicConfig(filename='logs/identity_creation.log', level=logging.INFO, format='%(asctime)s - %(message)s')

def execute_dfx_command(command):
    """Executes a shell command and logs the output."""
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    if result.returncode == 0:
        output = result.stdout.strip()
        logging.info(f"Command: {command}")
        logging.info(f"Output: {output}")
        return output
    else:
        error_message = f"Command failed: {command}\n{result.stderr.strip()}"
        logging.error(error_message)
        raise Exception(error_message)

def create_identity(identity_name):
    """Creates a new DFX identity with the given name."""
    command = f"dfx identity new {identity_name}"
    return execute_dfx_command(command)

def main():
    """Main function to prompt for the number of identities and create them."""
    try:
        num_identities = int(input("Enter the number of identities to create: "))
        if num_identities < 1:
            raise ValueError("Number of identities must be at least 1.")
    except ValueError as e:
        print(f"Invalid input: {e}")
        sys.exit(1)

    for i in range(num_identities):
        identity_name = f"player{i}"
        logging.info(f"Creating identity: {identity_name}")
        print(f"Creating identity: {identity_name}")
        create_identity(identity_name)

    print("Identity creation complete.")

if __name__ == "__main__":
    main()
