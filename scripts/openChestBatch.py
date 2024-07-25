import subprocess
import re
import random

def execute_dfx_command(command):
    """Executes a shell command and returns the output."""
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    if result.returncode == 0:
        return result.stdout.strip()
    else:
        raise Exception(f"Command failed: {command}\n{result.stderr.strip()}")

def get_principal():
    """Gets the principal ID."""
    command = "dfx identity get-principal"
    return execute_dfx_command(command)

def call_icrc7_tokens_of(principal):
    """Calls the icrc7_tokens_of method with the given principal."""
    command = f'dfx canister call chests icrc7_tokens_of \'(record {{ owner = principal "{principal}"; subaccount = null }})\''
    return execute_dfx_command(command)

def parse_tokens(output):
    """Parses the nat values from the icrc7_tokens_of output."""
    match = re.search(r'vec \{(.*?)\}', output, re.DOTALL)
    if match:
        tokens_str = match.group(1)
        tokens = re.findall(r'\d+(?:_\d+)*', tokens_str)
        return [int(token.replace('_', '')) for token in tokens]
    else:
        raise Exception("Failed to parse tokens from output")

def call_open_chests_batch(tokens):
    """Calls the openChestsBatch method with the given tokens."""
    tokens_str = '; '.join([f'{token} : nat' for token in tokens])
    command = f'dfx canister call cosmicrafts openChestsBatch \'(vec {{ {tokens_str} }})\''
    return execute_dfx_command(command)

def main():
    try:
        # Step 1: Get the principal ID
        principal = get_principal()
        print(f"Principal: {principal}")

        # Step 2: Call icrc7_tokens_of
        icrc7_output = call_icrc7_tokens_of(principal)
        print(f"icrc7_tokens_of output: {icrc7_output}")

        # Step 3: Parse the tokens
        tokens = parse_tokens(icrc7_output)
        print(f"Parsed tokens: {tokens}")

        # Step 4: Prompt the user to open all chests or a specific number
        open_all = input("Do you want to open all chests? (y/n): ").strip().lower() == 'y'
        if not open_all:
            num_chests_to_open = int(input(f"Enter the number of chests to open (max {len(tokens)}): ").strip())
            tokens = random.sample(tokens, min(num_chests_to_open, len(tokens)))

        # Step 5: Call openChestsBatch
        open_chests_output = call_open_chests_batch(tokens)
        print(f"openChestsBatch output: {open_chests_output}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
