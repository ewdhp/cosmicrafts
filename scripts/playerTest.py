import subprocess
import json
import logging
import time
import random

# Set up logging
logging.basicConfig(filename='logs/test.log', level=logging.INFO, format='%(asctime)s - %(message)s')

def execute_dfx_command(command):
    """Executes a shell command and logs the output."""
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    if result.returncode == 0:
        logging.info(f"Command: {command}")
        logging.info(f"Output: {result.stdout.strip()}")
        return result.stdout.strip()
    else:
        error_message = f"Command failed: {command}\n{result.stderr.strip()}"
        logging.error(error_message)
        raise Exception(error_message)

def switch_identity(identity_name):
    """Switches the DFX identity."""
    execute_dfx_command(f"dfx identity use {identity_name}")

def register_player(identity_name, username, avatar):
    """Registers a new player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts registerPlayer \'("{username}", {avatar})\''
    return execute_dfx_command(command)

def update_username(identity_name, username):
    """Updates the player's username."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts updateUsername \'("{username}")\''
    return execute_dfx_command(command)

def update_avatar(identity_name, avatar):
    """Updates the player's avatar."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts updateAvatar \'({avatar})\''
    return execute_dfx_command(command)

def update_description(identity_name, description):
    """Updates the player's description."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts updateDescription \'("{description}")\''
    return execute_dfx_command(command)

def send_friend_request(identity_name, friend_id):
    """Sends a friend request to another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts sendFriendRequest \'("{friend_id}")\''
    return execute_dfx_command(command)

def accept_friend_request(identity_name, from_id):
    """Accepts a friend request from another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts acceptFriendRequest \'("{from_id}")\''
    return execute_dfx_command(command)

def decline_friend_request(identity_name, from_id):
    """Declines a friend request from another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts declineFriendRequest \'("{from_id}")\''
    return execute_dfx_command(command)

def block_user(identity_name, blocked_id):
    """Blocks another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts blockUser \'("{blocked_id}")\''
    return execute_dfx_command(command)

def unblock_user(identity_name, blocked_id):
    """Unblocks another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts unblockUser \'("{blocked_id}")\''
    return execute_dfx_command(command)

def set_privacy_setting(identity_name, setting):
    """Sets the player's privacy setting."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts setPrivacySetting \'("{setting}")\''
    return execute_dfx_command(command)

def get_notifications(identity_name):
    """Gets notifications for the player."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts getNotifications'
    return execute_dfx_command(command)

def get_friend_requests(identity_name):
    """Gets pending friend requests for the player."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts getFriendRequests'
    return execute_dfx_command(command)

def get_my_privacy_settings(identity_name):
    """Gets the player's privacy settings."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts getMyPrivacySettings'
    return execute_dfx_command(command)

def get_player(identity_name):
    """Gets the player's profile."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts getPlayer'
    return execute_dfx_command(command)

def get_profile(identity_name, player_id):
    """Gets another player's profile."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts getProfile \'("{player_id}")\''
    return execute_dfx_command(command)

def get_full_user_profile(identity_name, player_id):
    """Gets the full profile of another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts getFullUserProfile \'("{player_id}")\''
    return execute_dfx_command(command)

def search_user_by_username(identity_name, username):
    """Searches for a player by username."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts searchUserByUsername \'("{username}")\''
    return execute_dfx_command(command)

def get_friends_list(identity_name):
    """Gets the player's friends list."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts getFriendsList'
    return execute_dfx_command(command)

def get_all_players():
    """Gets the list of all registered players."""
    command = 'dfx canister call cosmicrafts getAllPlayers'
    return execute_dfx_command(command)

def main():
    try:
        # Setup test accounts
        accounts = ["player1", "player2", "player3"]
        usernames = ["PlayerOne", "PlayerTwo", "PlayerThree"]
        avatars = [1, 2, 3]
        
        for account, username, avatar in zip(accounts, usernames, avatars):
            register_player(account, username, avatar)

        # Validate registration
        all_players = get_all_players()
        logging.info(f"All players after registration: {all_players}")

        # Update player information
        update_username("player1", "NewPlayerOne")
        update_avatar("player1", 2)
        update_description("player1", "This is a test description")

        # Send and manage friend requests
        send_friend_request("player1", "player2")
        get_friend_requests("player2")
        accept_friend_request("player2", "player1")
        get_friends_list("player1")
        decline_friend_request("player1", "player3")

        # Block and unblock users
        block_user("player1", "player3")
        unblock_user("player1", "player3")

        # Set privacy settings
        set_privacy_setting("player1", "#acceptAll")
        get_my_privacy_settings("player1")

        # Query player data
        get_notifications("player1")
        get_profile("player1", "player2")
        get_full_user_profile("player1", "player2")
        search_user_by_username("player1", "PlayerTwo")

        # Log all players after updates
        all_players = get_all_players()
        logging.info(f"All players after updates: {all_players}")

    except Exception as e:
        logging.error(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
