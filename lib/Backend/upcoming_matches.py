import requests
import pandas as pd
from datetime import datetime
from sqlalchemy import create_engine, MetaData, Table, Column, String, Integer
import urllib.parse
import sys

# --- Step 1: Fetch Data from TBA ---
api_key = "tcS4SqWjusf1dO6Nqi3kzMO0aHUg9wcJk2MUaPbtH4xnZmWQj5lfW43ab3speDKA"
event_key = "2025idbo"  # Event key for the event
url = f"https://www.thebluealliance.com/api/v3/event/{event_key}/matches"
headers = {"X-TBA-Auth-Key": api_key}

print(f"Fetching match data from TBA for event {event_key}...")
response = requests.get(url, headers=headers)

# Check if the request was successful
if response.status_code != 200:
    print(f"Error fetching data from TBA: {response.status_code}")
    print(response.text)
    sys.exit(1)

matches_json = response.json()
print(f"Retrieved {len(matches_json)} matches from TBA")

# Filter for qualification matches (comp_level: 'qm')
qualification_matches = [match for match in matches_json if match.get('comp_level') == 'qm']
print(f"Found {len(qualification_matches)} qualification matches")

# Check if we have matches to process
if not qualification_matches:
    print("No qualification matches found. Exiting.")
    sys.exit(0)

# --- Step 2: Sort and Process the Matches ---
qualification_matches_sorted = sorted(qualification_matches, key=lambda m: m.get('time', 0))

# Convert Unix timestamps to human-readable datetime strings
for match in qualification_matches_sorted:
    unix_time = match.get('time')
    if unix_time:
        match['scheduled_time_readable'] = datetime.fromtimestamp(unix_time).strftime('%Y-%m-%d %H:%M:%S')
    else:
        match['scheduled_time_readable'] = None

# Build a list of dictionaries, one row per alliance per match (without the score)
data = []
for match in qualification_matches_sorted:
    alliances = match.get('alliances', {})
    for alliance_color, alliance_info in alliances.items():
        data.append({
             'match_number': match.get('match_number'),
             'scheduled_time': match.get('scheduled_time_readable'),
             'comp_level': match.get('comp_level'),
             'match_key': match.get('key'),
             'alliance': alliance_color,
             'team_keys': ', '.join(alliance_info.get('team_keys', []))
        })

# Create the DataFrame
df_alliances = pd.DataFrame(data)
print(f"Created DataFrame with {len(df_alliances)} rows")
print(df_alliances.head())

# Check if we have data to save
if df_alliances.empty:
    print("DataFrame is empty. Exiting without updating the database.")
    sys.exit(0)

# --- Step 3: Connect to MSSQL and Store the Data ---
username = "1148Robotics"
password = "1148Robotics"
server = "MT-server\\SQLEXPRESS"  # Named instance; note the double backslash
database = "1148-Scouting"

# Build URL-encoded ODBC connection string
params = urllib.parse.quote_plus(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)
connection_string = "mssql+pyodbc:///?odbc_connect=" + params
engine = create_engine(connection_string)

# Define data types explicitly to avoid SQL errors
dtypes = {
    'match_number': Integer,
    'scheduled_time': String(30),
    'comp_level': String(10),
    'match_key': String(50),
    'alliance': String(10),
    'team_keys': String(100)
}

try:
    # Write the DataFrame to a table called 'QualificationMatches'
    print("Writing data to SQL Server...")
    df_alliances.to_sql('QualificationMatches', con=engine, if_exists='replace', 
                         index=False, dtype=dtypes)
    print("Data successfully written to database!")
except Exception as e:
    print(f"Error writing to database: {str(e)}")