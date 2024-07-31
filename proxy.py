import requests
import json

base_url = "https://dashboard.cosmicrafts.com/api"

def log_request_response(method, url, data=None):
    if data:
        print(f"Calling {method} {url}\nRequest Data: {json.dumps(data, indent=2)}")
        response = requests.request(method, url, json=data)
    else:
        print(f"Calling {method} {url}")
        response = requests.request(method, url)
    
    try:
        response_json = response.json()
    except json.JSONDecodeError:
        response_json = response.text

    print(f"{response.status_code}, {response_json}\n")

user_id = "vam5o-bdiga-izgux-6cjaz-53tck-eezzo-fezki-t2sh6-xefok-dkdx7-pae"
friend_id = "jv5nw-6iuco-7br3x-zuttd-iwmhy-fsyvg-q6uak-t3a3t-6evep-bojcq-4ae"

register_player_data = {"userId": user_id, "username": "BiZKiT", "avatarId": 4}
log_request_response("POST", f"{base_url}/registerPlayer", register_player_data)

log_request_response("GET", f"{base_url}/getAllPlayers")

get_player_data = {"userId": user_id}
log_request_response("POST", f"{base_url}/getPlayer", get_player_data)

log_request_response("GET", f"{base_url}/getProfile/{user_id}")

update_username_data = {"userId": user_id, "newUsername": "NewName"}
log_request_response("POST", f"{base_url}/updateUsername", update_username_data)

update_avatar_data = {"userId": user_id, "newAvatarId": 2}
log_request_response("POST", f"{base_url}/updateAvatar", update_avatar_data)

update_description_data = {"userId": user_id, "newDescription": "This is a new description"}
log_request_response("POST", f"{base_url}/updateDescription", update_description_data)

send_friend_request_data = {"userId": user_id, "friendId": friend_id}
log_request_response("POST", f"{base_url}/sendFriendRequest", send_friend_request_data)

accept_friend_request_data = {"userId": user_id, "friendId": friend_id}
log_request_response("POST", f"{base_url}/acceptFriendRequest", accept_friend_request_data)

get_friends_list_data = {"userId": user_id}
log_request_response("POST", f"{base_url}/getFriendsList", get_friends_list_data)

get_friend_requests_data = {"userId": user_id}
log_request_response("POST", f"{base_url}/getFriendRequests", get_friend_requests_data)

set_privacy_setting_data = {"userId": user_id, "setting": "acceptAll"}
log_request_response("POST", f"{base_url}/setPrivacySetting", set_privacy_setting_data)

get_privacy_settings_data = {"userId": user_id}
log_request_response("POST", f"{base_url}/getMyPrivacySettings", get_privacy_settings_data)

get_notifications_data = {"userId": user_id}
log_request_response("POST", f"{base_url}/getNotifications", get_notifications_data)
