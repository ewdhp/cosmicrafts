import subprocess
import json
import logging
import sys
from datetime import datetime, timedelta

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s', handlers=[
    logging.FileHandler("logs/test.log"),
    logging.StreamHandler(sys.stdout)
])

def execute_dfx_command(command):
    """Executes a shell command and logs the output."""
    logging.info(f"Running command: {command}")
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    if result.returncode == 0:
        logging.info(f"Output: {result.stdout.strip()}")
        return result.stdout.strip()
    else:
        error_message = f"Command failed: {command}\n{result.stderr.strip()}"
        logging.error(error_message)
        raise Exception(error_message)

def switch_identity(identity_name):
    """Switches the DFX identity."""
    execute_dfx_command(f"dfx identity use {identity_name}")

def get_principal(identity_name):
    """Gets the principal ID of the current identity."""
    switch_identity(identity_name)
    command = "dfx identity get-principal"
    principal = execute_dfx_command(command)
    return principal

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
    command = f'dfx canister call cosmicrafts sendFriendRequest \'(principal "{friend_id}")\''
    return execute_dfx_command(command)

def accept_friend_request(identity_name, from_id):
    """Accepts a friend request from another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts acceptFriendRequest \'(principal "{from_id}")\''
    return execute_dfx_command(command)

def block_user(identity_name, blocked_id):
    """Blocks another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts blockUser \'(principal "{blocked_id}")\''
    return execute_dfx_command(command)

def unblock_user(identity_name, blocked_id):
    """Unblocks another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts unblockUser \'(principal "{blocked_id}")\''
    return execute_dfx_command(command)

def set_privacy_setting(identity_name, setting):
    """Sets the player's privacy setting."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts setPrivacySetting \'(variant {{ {setting} }})\''
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

def get_friends_list(identity_name):
    """Gets the player's friends list."""
    switch_identity(identity_name)
    command = 'dfx canister call cosmicrafts getFriendsList'
    return execute_dfx_command(command)

def get_profile(identity_name, player_id):
    """Gets another player's profile."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts getProfile \'(principal "{player_id}")\''
    return execute_dfx_command(command)

def get_full_user_profile(identity_name, player_id):
    """Gets the full profile of another player."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts getFullUserProfile \'(principal "{player_id}")\''
    return execute_dfx_command(command)

def search_user_by_username(identity_name, username):
    """Searches for a player by username."""
    switch_identity(identity_name)
    command = f'dfx canister call cosmicrafts searchUserByUsername \'("{username}")\''
    return execute_dfx_command(command)

def test_registration():
    """Test player registration."""
    logging.info("Testing player registration...")
    try:
        register_player("player4", "ValidUser", 4)
        register_player("player5", "ValidUser", 5)  # Same username, different principal

        try:
            register_player("player6", "ThisUsernameIsWayTooLong", 6)
        except Exception as e:
            logging.info(f"Expected error for long username: {e}")

    except Exception as e:
        logging.error(f"Error during registration tests: {e}")

def test_updates():
    """Test updating player information."""
    logging.info("Testing player updates...")
    try:
        update_username("player1", "UpdatedUser")
        try:
            update_username("player1", "ThisUsernameIsWayTooLong")
        except Exception as e:
            logging.info(f"Expected error for long username: {e}")

        update_avatar("player1", 5)
        update_description("player1", "This is a valid description.")
        try:
            update_description("player1", "x" * 200)
        except Exception as e:
            logging.info(f"Expected error for long description: {e}")

    except Exception as e:
        logging.error(f"Error during update tests: {e}")

def test_friend_requests():
    """Test sending and managing friend requests."""
    logging.info("Testing friend requests...")
    try:
        try:
            send_friend_request("player1", principals["player1"])
        except Exception as e:
            logging.info(f"Expected error for self friend request: {e}")

        send_friend_request("player1", principals["player2"])
        try:
            send_friend_request("player1", principals["player2"])
        except Exception as e:
            logging.info(f"Expected error for duplicate friend request: {e}")

        accept_friend_request("player2", principals["player1"])
        try:
            accept_friend_request("player2", principals["player1"])
        except Exception as e:
            logging.info(f"Expected error for non-existent friend request: {e}")

        friends_list = get_friends_list("player1")
        assert principals["player2"] in friends_list, "Should be friends now"
        
        # Attempting to send a friend request after being friends should fail
        try:
            send_friend_request("player1", principals["player2"])
        except Exception as e:
            logging.info(f"Expected error for friend request after being friends: {e}")

        # Ensure friend request shows up in the list
        friend_requests = get_friend_requests("player2")
        assert not any(req['from'] == principals["player1"] for req in friend_requests), "Friend request should not be found after acceptance"

        block_user("player2", principals["player1"])
        try:
            send_friend_request("player1", principals["player2"])
        except Exception as e:
            logging.info(f"Expected error for friend request from blocked user: {e}")

        unblock_user("player2", principals["player1"])

    except Exception as e:
        logging.error(f"Error during friend request tests: {e}")

def test_blocking():
    """Test blocking and unblocking users."""
    logging.info("Testing blocking and unblocking...")
    try:
        try:
            block_user("player1", principals["player1"])
        except Exception as e:
            logging.info(f"Expected error for blocking oneself: {e}")

        block_user("player1", principals["player3"])
        try:
            block_user("player1", principals["player3"])
        except Exception as e:
            logging.info(f"Expected error for already blocked user: {e}")

        set_privacy_setting("player1", "blockAll")
        try:
            send_friend_request("player3", principals["player1"])
        except Exception as e:
            logging.info(f"Expected error for friend request with blockAll privacy setting: {e}")

        unblock_user("player1", principals["player3"])

    except Exception as e:
        logging.error(f"Error during blocking tests: {e}")

def test_privacy_settings():
    """Test setting and getting privacy settings."""
    logging.info("Testing privacy settings...")
    try:
        set_privacy_setting("player1", "blockAll")
        try:
            send_friend_request("player3", principals["player1"])
        except Exception as e:
            logging.info(f"Expected error for friend request with blockAll privacy setting: {e}")

        set_privacy_setting("player1", "acceptAll")

    except Exception as e:
        logging.error(f"Error during privacy setting tests: {e}")

def test_notifications():
    """Test notifications."""
    logging.info("Testing notifications...")
    try:
        set_privacy_setting("player1", "friendsOfFriends")
        notifications = get_notifications("player1")
        logging.info(f"Notifications for player1: {notifications}")

    except Exception as e:
        logging.error(f"Error during notification tests: {e}")

def test_profiles():
    """Test retrieving profiles and data."""
    logging.info("Testing profile retrieval...")
    try:
        profile = get_profile("player1", principals["player2"])
        logging.info(f"Profile of player2: {profile}")

        full_profile = get_full_user_profile("player1", principals["player2"])
        logging.info(f"Full profile of player2: {full_profile}")

        search_results = search_user_by_username("player1", "PlayerTwo")
        logging.info(f"Search results for PlayerTwo: {search_results}")

    except Exception as e:
        logging.error(f"Error during profile retrieval tests: {e}")

def main():
    try:
        accounts = ["player1", "player2", "player3", "player4", "player5", "player6"]
        usernames = ["PlayerOne", "PlayerTwo", "PlayerThree", "PlayerFour", "PlayerFive", "PlayerSix"]
        avatars = [1, 2, 3, 4, 5, 6]
        global principals
        principals = {}

        for account, username, avatar in zip(accounts, usernames, avatars):
            principal = get_principal(account)
            principals[account] = principal
            register_player(account, username, avatar)

        test_registration()
        test_updates()
        test_friend_requests()
        test_blocking()
        test_privacy_settings()
        test_notifications()
        test_profiles()

    except Exception as e:
        logging.error(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
