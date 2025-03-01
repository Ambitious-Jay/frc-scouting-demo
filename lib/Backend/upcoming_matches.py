import requests
import pandas as pd
from datetime import datetime
from sqlalchemy import create_engine
import urllib.parse

# --- Step 1: Fetch Data from TBA ---
api_key = "tcS4SqWjusf1dO6Nqi3kzMO0aHUg9wcJk2MUaPbtH4xnZmWQj5lfW43ab3speDKA"
event_key = "2025caoc"  # Event key for the event
url = f"https://www.thebluealliance.com/api/v3/event/{event_key}/matches"
headers = {"X-TBA-Auth-Key": api_key}

response = requests.get(url, headers=headers)
matches_json = response.json()

# Filter for qualification matches (comp_level: 'qm')
qualification_matches = [match for match in matches_json if match.get('comp_level') == 'qm']

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
print(df_alliances)

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

# Write the DataFrame to a table called 'qualification_match_alliances'
df_alliances.to_sql('QualificationMatches', con=engine, if_exists='replace', index=False)
