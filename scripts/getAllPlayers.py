import subprocess
import re
import pandas as pd

def fetch_data_from_canister():
    try:
        # Run the dfx canister call command
        result = subprocess.run(['dfx', 'canister', 'call', 'cosmicrafts', 'getAllPlayers'], capture_output=True, text=True)
        
        # Check for errors in the subprocess call
        if result.returncode != 0:
            print(f"Error: {result.stderr}")
            return None

        # Print the raw output for debugging
        raw_output = result.stdout
        print(f"Raw output: {raw_output}")

        # Parse the raw output
        data = parse_raw_output(raw_output)
        return data
    
    except Exception as e:
        print(f"Exception occurred: {e}")
        return None

def parse_raw_output(raw_output):
    # Use a regex to find all records
    pattern = re.compile(r'record\s*{\s*id\s*=\s*principal\s*"([^"]+)";\s*elo\s*=\s*([\d.]+)\s*:\s*float64;\s*name\s*=\s*"([^"]+)";\s*level\s*=\s*(\d+)\s*:\s*nat;\s*}')
    matches = pattern.findall(raw_output)

    # Convert matches to a list of dictionaries
    data = []
    for match in matches:
        data.append({
            'id': match[0],
            'elo': float(match[1]),
            'name': match[2],
            'level': int(match[3])
        })

    return data

def format_data(data, csv_file):
    # Convert the data to a DataFrame
    df = pd.DataFrame(data)
    
    # Set display options to show more rows and columns
    pd.set_option('display.max_rows', None)  # Show all rows
    pd.set_option('display.max_columns', None)  # Show all columns
    
    # Print the DataFrame in a readable format
    print(df)
    
    # Save the DataFrame to a CSV file
    df.to_csv(csv_file, index=False)
    print(f"Data exported to {csv_file}")

def main():
    # Fetch data
    data = fetch_data_from_canister()
    
    if data:
        # Specify the CSV file name
        csv_file = 'logs/players_data.csv'
        
        # Format and display data
        format_data(data, csv_file)

if __name__ == "__main__":
    main()
