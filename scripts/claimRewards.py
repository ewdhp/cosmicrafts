import subprocess
import re
import json

def execute_command(command):
    print(f"Executing: {command}")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        print(result.stdout.strip())
        return result.stdout.strip()
    else:
        print(f"Error executing {command}: {result.stderr.strip()}")
        return None

def format_to_json_string(output):
    # Replace and format the string to JSON
    output = output.replace("(", "[").replace(")", "]")
    output = output.replace("vec {", "[").replace("record {", "{").replace("variant {", "{\"").replace("};", "\"}").replace(";", ",")
    output = re.sub(r"(\w+) = ", r'"\1": ', output)
    output = output.replace(" : nat64", "").replace(" : nat", "").replace(" : bool", "")
    output = output.replace(" false", "false").replace(" true", "true")
    output = re.sub(r'{ (\w+) }', r'{"\1"}', output)  # Fix variant formatting

    # Remove any trailing commas within objects and arrays
    output = re.sub(r",\s*}", "}", output)
    output = re.sub(r",\s*]", "]", output)

    return output

# Step 1: Fetch the list of missions
missions_output = execute_command("dfx canister call cosmicrafts getGeneralMissions")

# Step 2: Parse the missions output
if missions_output:
    # Debug: Print raw missions output
    print("Raw missions output:")
    print(missions_output)
    
    # Format to JSON string
    formatted_json_str = format_to_json_string(missions_output)

    # Debug: Print formatted JSON string
    print("Formatted JSON string:")
    print(formatted_json_str)
    
    try:
        missions_json = json.loads(formatted_json_str)
        print("Parsed JSON:")
        print(missions_json)

        finished_missions = [mission for mission in missions_json if mission["finished"]]

        uuid = None
        for mission in finished_missions:
            mission_id = mission["id_mission"]
            claim_command = f"dfx canister call cosmicrafts claimGeneralReward '({mission_id} : nat)'"
            claim_output = execute_command(claim_command)
            if claim_output and "Chest minted and reward claimed" in claim_output:
                match = re.search(r"UUID: (\d+)", claim_output)
                if match:
                    uuid = match.group(1)
                    break

        if uuid:
            # Step 3: Open the chest with the extracted UUID
            open_chest_command = f"dfx canister call cosmicrafts openChest '({uuid} : nat)'"
            execute_command(open_chest_command)
        else:
            print("Failed to extract UUID from claimReward command output.")
    except json.JSONDecodeError as e:
        print(f"JSONDecodeError: {e}")
        print("Formatted JSON string causing error:")
        print(formatted_json_str)
else:
    print("Failed to fetch missions.")

print("All commands executed.")
