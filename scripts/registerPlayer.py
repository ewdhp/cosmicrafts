import subprocess
import logging
import random
import string
import asyncio
import time

# Set up logging
#logging.basicConfig(filename='logs/register_users.log', level=logging.INFO, format='%(asctime)s - %(message)s')

async def execute_dfx_command(command, log_output=True):
    """Executes a shell command asynchronously and logs the output."""
    process = await asyncio.create_subprocess_shell(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = await process.communicate()
    
    if process.returncode != 0:
        error_message = f"Command failed: {command}\n{stderr.decode().strip()}"
        logging.error(error_message)
        if log_output:
            print(error_message)
        return False, stderr.decode().strip()
    else:
        output = stdout.decode().strip()
        logging.info(f"Command output: {output}")
        if log_output:
            print(output)
        return True, output

async def switch_identity(identity_name):
    """Switches the DFX identity asynchronously."""
    command = f"dfx identity use {identity_name}"
    return await execute_dfx_command(command, log_output=False)

def generate_random_username(length=12):
    """Generates a random username with a specified length."""
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

async def register_user(semaphore, user, username, avatar_id):
    """Switches identity and registers a user using the registerPlayer canister method."""
    async with semaphore:
        retries = 3
        for attempt in range(retries):
            try:
                logging.info(f"Switching to identity {user}")
                success, output = await switch_identity(user)
                if not success:
                    raise Exception(f"Failed to switch identity: {output}")
                
                logging.info(f"Identity switched to {user}, now making canister call")
                command = f'dfx canister call cosmicrafts registerPlayer \'("{username}", {avatar_id})\''
                success, output = await execute_dfx_command(command)
                if not success:
                    raise Exception(f"Canister call failed: {output}")
                
                logging.info(f"Finished registration for {user}")
                print(f"Registration successful: Username: {username}, Output: {output}")
                break
            except Exception as e:
                error_message = f"Error registering {user} on attempt {attempt + 1}: {e}"
                logging.error(error_message)
                if attempt == retries - 1:
                    print(error_message)
                await asyncio.sleep(1)  # Wait before retrying

async def main():
    """Main function to register users."""
    num_users = int(input("Enter the number of users to register: "))

    users = [f"player{i}" for i in range(1, num_users + 1)]  # Create player identities
    user_data = [(user, generate_random_username(), random.randint(1, 33)) for user in users]  # Pre-generate usernames and avatar IDs

    semaphore = asyncio.Semaphore(1)  # Allow only one identity switch and canister call at a time

    tasks = [register_user(semaphore, user, username, avatar_id) for user, username, avatar_id in user_data]

    await asyncio.gather(*tasks)

    # Switch back to the bizkit identity at the end
    logging.info("Switching back to bizkit identity")
    await switch_identity("bizkit")

if __name__ == "__main__":
    asyncio.run(main())
