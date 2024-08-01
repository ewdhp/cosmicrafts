import subprocess

def run_dfx_command(command, input_data=None):
    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    if input_data:
        out, err = process.communicate(input_data.encode())
    else:
        out, err = process.communicate()
    return out.decode(), err.decode()

def create_category(name, achievements, required_progress, rewards):
    achievements_str = "; ".join(map(str, achievements))
    rewards_str = "; ".join([f'record {{ rewardType = variant {{ {reward["rewardType"]} }}; amount = {reward["amount"]} }}' for reward in rewards])
    input_data = f'("{name}", vec {{ {achievements_str} }}, {required_progress}, vec {{ {rewards_str} }})'
    print("Create Category Input Data:", input_data)
    command = f"dfx canister call cosmicrafts createCategory --ic '{input_data}'"
    out, err = run_dfx_command(command, input_data)
    return out, err

def create_achievement(name, individual_achievements, required_progress, category_id, rewards):
    individual_achievements_str = "; ".join(map(str, individual_achievements))
    rewards_str = "; ".join([f'record {{ rewardType = variant {{ {reward["rewardType"]} }}; amount = {reward["amount"]} }}' for reward in rewards])
    input_data = f'("{name}", vec {{ {individual_achievements_str} }}, {required_progress}, {category_id}, vec {{ {rewards_str} }})'
    print("Create Achievement Input Data:", input_data)
    command = f"dfx canister call cosmicrafts createAchievement --ic '{input_data}'"
    out, err = run_dfx_command(command, input_data)
    return out, err

def create_individual_achievement(name, achievement_type, required_progress, rewards, achievement_id):
    rewards_str = "; ".join([f'record {{ rewardType = variant {{ {reward["rewardType"]} }}; amount = {reward["amount"]} }}' for reward in rewards])
    input_data = f'("{name}", variant {{ {achievement_type} }}, {required_progress}, vec {{ {rewards_str} }}, {achievement_id})'
    print("Create Individual Achievement Input Data:", input_data)
    command = f"dfx canister call cosmicrafts createIndividualAchievement --ic '{input_data}'"
    out, err = run_dfx_command(command, input_data)
    return out, err

def get_achievements():
    command = "dfx canister call cosmicrafts getAchievements --ic"
    print("Get Achievements Command:", command)
    out, err = run_dfx_command(command)
    return out, err

# Example usage with different categories, achievements, and individual achievements:
categories = [
    {"name": "Category 1", "achievements": [1, 2], "required_progress": 50, "rewards": [{"rewardType": "Flux", "amount": 100}, {"rewardType": "CosmicPower", "amount": 50}]},
    {"name": "Category 2", "achievements": [3, 4], "required_progress": 60, "rewards": [{"rewardType": "CosmicPower", "amount": 75}, {"rewardType": "Flux", "amount": 150}]}
]

achievements = [
    {"name": "Achievement 1", "individual_achievements": [1, 2], "required_progress": 30, "category_id": 1, "rewards": [{"rewardType": "Flux", "amount": 50}, {"rewardType": "CosmicPower", "amount": 25}]},
    {"name": "Achievement 2", "individual_achievements": [3, 4], "required_progress": 40, "category_id": 1, "rewards": [{"rewardType": "CosmicPower", "amount": 30}, {"rewardType": "Flux", "amount": 60}]},
    {"name": "Achievement 3", "individual_achievements": [5, 6], "required_progress": 35, "category_id": 2, "rewards": [{"rewardType": "Flux", "amount": 45}, {"rewardType": "CosmicPower", "amount": 20}]},
    {"name": "Achievement 4", "individual_achievements": [7, 8], "required_progress": 45, "category_id": 2, "rewards": [{"rewardType": "CosmicPower", "amount": 40}, {"rewardType": "Flux", "amount": 70}]}
]

individual_achievements = [
    {"name": "Individual Achievement 1", "type": "UnitsDeployed", "required_progress": 10, "rewards": [{"rewardType": "Flux", "amount": 10}], "achievement_id": 1},
    {"name": "Individual Achievement 2", "type": "UnitsDeployed", "required_progress": 15, "rewards": [{"rewardType": "CosmicPower", "amount": 5}], "achievement_id": 1},
    {"name": "Individual Achievement 3", "type": "UnitsDeployed", "required_progress": 20, "rewards": [{"rewardType": "Flux", "amount": 20}], "achievement_id": 2},
    {"name": "Individual Achievement 4", "type": "UnitsDeployed", "required_progress": 25, "rewards": [{"rewardType": "CosmicPower", "amount": 10}], "achievement_id": 2},
    {"name": "Individual Achievement 5", "type": "UnitsDeployed", "required_progress": 30, "rewards": [{"rewardType": "Flux", "amount": 30}], "achievement_id": 3},
    {"name": "Individual Achievement 6", "type": "UnitsDeployed", "required_progress": 35, "rewards": [{"rewardType": "CosmicPower", "amount": 15}], "achievement_id": 3},
    {"name": "Individual Achievement 7", "type": "UnitsDeployed", "required_progress": 40, "rewards": [{"rewardType": "Flux", "amount": 40}], "achievement_id": 4},
    {"name": "Individual Achievement 8", "type": "UnitsDeployed", "required_progress": 45, "rewards": [{"rewardType": "CosmicPower", "amount": 20}], "achievement_id": 4}
]

# Create Categories
for category in categories:
    out, err = create_category(category["name"], category["achievements"], category["required_progress"], category["rewards"])
    print("Create Category Output:", out)
    if err:
        print("Create Category Error:", err)

# Create Achievements
for achievement in achievements:
    out, err = create_achievement(achievement["name"], achievement["individual_achievements"], achievement["required_progress"], achievement["category_id"], achievement["rewards"])
    print("Create Achievement Output:", out)
    if err:
        print("Create Achievement Error:", err)

# Create Individual Achievements
for individual_achievement in individual_achievements:
    out, err = create_individual_achievement(individual_achievement["name"], individual_achievement["type"], individual_achievement["required_progress"], individual_achievement["rewards"], individual_achievement["achievement_id"])
    print("Create Individual Achievement Output:", out)
    if err:
        print("Create Individual Achievement Error:", err)

# Get Achievements
out, err = get_achievements()
print("Get Achievements Output:", out)
if err:
    print("Get Achievements Error:", err)
