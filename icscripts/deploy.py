import subprocess
import pexpect

def run_command(command):
    """Run a shell command and print its output."""
    print(f"Executing: {command}")
    process = subprocess.run(command, shell=True, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(process.stdout)
    print(process.stderr)

def run_expect_script(command, prompts_responses):
    """Run an expect script using pexpect."""
    print(f"Executing expect script for: {command}")
    child = pexpect.spawn(command)
    for prompt, response in prompts_responses:
        child.expect(prompt)
        child.sendline(response)
    child.expect(pexpect.EOF)
    print(child.before.decode())

# List of shell commands to run
commands = [
    "reset",
    "dfx identity use bizkit",
    "dfx canister uninstall-code cosmicrafts --ic",
    "dfx deploy cosmicrafts --ic",
    "dfx canister call cosmicrafts adminManagement '(variant { CreateMissionsPeriodically })' --ic",
    # "python scripts/missions.py" # Uncomment if you want to include this
]

# Run shell commands
for command in commands:
    run_command(command)

# Inline expect script for registerPlayer.py
register_player_script = "python icscripts/registerPlayer.py"
register_player_prompts = [
    ("Enter the number of users to register: ", "2")
]
run_expect_script(register_player_script, register_player_prompts)

# Inline expect script for matchmaking.py
matchmaking_script = "python icscripts/matchmaking.py"
matchmaking_prompts = [
    ("Enter the number of matches to run: ", "1"),
    ("Do you want to loop indefinitely? (y/n): ", "n")
]
run_expect_script(matchmaking_script, matchmaking_prompts)

# Inline expect script for claimRewards.py
claim_rewards_script = "python icscripts/claimRewards.py"
claim_rewards_prompts = []
run_expect_script(claim_rewards_script, claim_rewards_prompts)

print("All commands executed successfully.")
