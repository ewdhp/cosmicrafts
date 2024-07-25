import subprocess

def execute_dfx_command(command):
    """Executes a shell command and returns the output."""
    print(f"Running command: {command}")
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    if result.returncode == 0:
        print(result.stdout.strip())
    else:
        raise Exception(f"Command failed: {command}\n{result.stderr.strip()}")

def main():
    try:
        # List of commands to run
        commands = [
            "reset",
            "dfx identity use bizkit",
            "dfx canister uninstall-code chests",
            "dfx canister uninstall-code cosmicrafts",
            "dfx deploy cosmicrafts",
            "dfx deploy chests --argument '( record {owner = principal \"bkyz2-fmaaa-aaaaa-qaaaq-cai\"; subaccount = null;}, record { \"name\" = \"Cosmicrafts Game NFTs\"; symbol = \"CS\"; royalties = null; royaltyRecipient = null; description = null; image = null; supplyCap = null; })'"
        ]
        
        # Execute each command
        for command in commands:
            execute_dfx_command(command)

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
