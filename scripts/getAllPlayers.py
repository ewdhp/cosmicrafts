import subprocess
import re
import pandas as pd
import os

def fetch_data_from_canister():
    try:
        # Run the dfx canister call command
        result = subprocess.run(['dfx', 'canister', 'call', 'cosmicrafts', 'getAllPlayers'], capture_output=True, text=True)
        
        # Check for errors in the subprocess call
        if result.returncode != 0:
            print(f"Error: {result.stderr}")
            return None

        # Parse the raw output
        data = parse_raw_output(result.stdout)
        return data
    
    except Exception as e:
        print(f"Exception occurred: {e}")
        return None

def parse_raw_output(raw_output):
    # Use a regex to find all records
    pattern = re.compile(
        r'record\s*{\s*id\s*=\s*principal\s*"([^"]+)";\s*'
        r'elo\s*=\s*([\d.]+)\s*:\s*float64;\s*'
        r'username\s*=\s*"([^"]+)";\s*'
        r'description\s*=\s*"([^"]*)";\s*'
        r'level\s*=\s*(\d+)\s*:\s*nat;\s*'
        r'registrationDate\s*=\s*([\d_]+)\s*:\s*int;\s*'
        r'friends\s*=\s*vec\s*{[^}]*};\s*'
        r'avatar\s*=\s*(\d+)\s*:\s*nat;\s*'
        r'}'
    )
    matches = pattern.findall(raw_output)

    # Convert matches to a list of dictionaries
    data = []
    for match in matches:
        registration_date = int(match[5].replace('_', ''))
        data.append({
            'id': match[0],
            'elo': float(match[1]),
            'username': match[2],
            'description': match[3],
            'level': int(match[4]),
            'registrationDate': registration_date,
            'avatar': int(match[6])
        })

    return data

def format_data(data, csv_file):
    # Convert the data to a DataFrame
    df = pd.DataFrame(data)
    
    # Convert the registration date to a readable format
    df['registrationDate'] = pd.to_datetime(df['registrationDate'], unit='ns')
    
    # Sort the DataFrame by ELO in descending order
    df = df.sort_values(by='elo', ascending=False)
    
    # Ensure the logs directory exists
    os.makedirs(os.path.dirname(csv_file), exist_ok=True)
    
    # Save the DataFrame to a CSV file
    df.to_csv(csv_file, index=False)
    print(f"Data successfully exported to {csv_file}")

def main():
    # Fetch data
    data = fetch_data_from_canister()
    
    if data:
        # Specify the CSV file name
        csv_file = 'logs/players_data.csv'
        
        # Format and display data
        format_data(data, csv_file)
    else:
        print("No data fetched from the canister.")

if __name__ == "__main__":
    main()
