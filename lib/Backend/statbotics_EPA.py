# Pip install statbotics PLEASEEE and the rest of the imports
import statbotics
import requests
import pyodbc
import sys

curEvent = "2025idbo"

def TBA_AddressFetcher(path):
    request_url = "https://www.thebluealliance.com/api/v3/" + path
    headers = {"X-TBA-Auth-Key": "tcS4SqWjusf1dO6Nqi3kzMO0aHUg9wcJk2MUaPbtH4xnZmWQj5lfW43ab3speDKA"}
    response = requests.get(request_url, headers=headers)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching data from TBA API: {response.status_code}")
        print(f"Response: {response.text}")
        return None

def TBA_EventOPRs(event):     
    opr_data = TBA_AddressFetcher("event/"+event+"/oprs")
    if opr_data is not None:
        return opr_data
    return None

# Get team list using a more reliable method - get teams directly
def get_event_teams(event_key):
    teams_data = TBA_AddressFetcher(f"event/{event_key}/teams/keys")
    if teams_data:
        return [team.replace('frc', '') for team in teams_data]
    return []

# Get OPR data or fall back to team list
opr_data = TBA_EventOPRs(curEvent)
if opr_data and 'ccwms' in opr_data:
    # If we have CCWM data, use it
    Teams = [team.replace('frc', '') for team in list(opr_data['ccwms'].keys())]
    print(f"Found {len(Teams)} teams using CCWM data")
elif opr_data and 'oprs' in opr_data:
    # If no CCWM but we have OPR data
    Teams = [team.replace('frc', '') for team in list(opr_data['oprs'].keys())]
    print(f"Found {len(Teams)} teams using OPR data")
else:
    # Fallback to getting teams directly
    Teams = get_event_teams(curEvent)
    print(f"Found {len(Teams)} teams using team list")

if not Teams:
    print(f"No teams found for event {curEvent}. The event might not have data yet.")
    sys.exit(1)

print(f"Teams: {Teams}")

sb = statbotics.Statbotics()

def saveEPA(team, name, total, auto, teleop, endgame, current, recent, mean, max):
    insert_sql = """
    INSERT INTO StatsboticsEPA (team, team_name, total_epa, auto_epa, teleop_epa, endgame_epa, norm_epa_current, norm_epa_recent, norm_epa_mean, norm_epa_max)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    cursor.execute(insert_sql,
                    team,
                    name,
                    total,
                    auto,
                    teleop,
                    endgame,
                    current,
                    recent,
                    mean,
                    max)
    conn.commit()
      
      
server = 'MT-server\\SQLEXPRESS'  # Added SQLEXPRESS instance name
database = '1148-Scouting'
username = '1148Robotics'
password = '1148Robotics'

# Create the connection string
connection_string = (
    f'DRIVER={{ODBC Driver 17 for SQL Server}};'
    f'SERVER={server};'
    f'DATABASE={database};'
    f'UID={username};'
    f'PWD={password};'
    f'TrustServerCertificate=yes;'
)

try:
    print("Connecting to database...")
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    
    print("Truncating StatsboticsEPA table...")
    cursor.execute("TRUNCATE TABLE StatsboticsEPA")
    conn.commit()
    
    for team in Teams:
        try:
            team_int = int(team)
            print(f"Processing team {team_int}...")
            
            # Get team event data
            team_event_data = sb.get_team_event(team_int, curEvent)
            if not team_event_data or 'epa' not in team_event_data or not team_event_data['epa'] or 'breakdown' not in team_event_data['epa']:
                print(f"No EPA data available for team {team_int} at event {curEvent}")
                continue
                
            epa = team_event_data['epa']['breakdown']
            
            # Get team data
            team_data = sb.get_team(team_int)
            if not team_data:
                print(f"No team data available for team {team_int}")
                continue
                
            name = team_data.get('name', f"Team {team_int}")
            total = epa.get('total_points', 0)
            auto = epa.get('auto_points', 0)
            teleop = epa.get('teleop_points', 0)
            endgame = epa.get('endgame_points', 0)
            
            norm_epa = team_data.get('norm_epa', {})
            current = norm_epa.get('current', 0)
            recent = norm_epa.get('recent', 0)
            mean = norm_epa.get('mean', 0)
            max_epa = norm_epa.get('max', 0)
            
            saveEPA(team_int, name, total, auto, teleop, endgame, current, recent, mean, max_epa)
            print(f"Successfully saved EPA data for team {team_int}")
            
        except Exception as team_error:
            print(f"Error processing team {team}: {team_error}")
    
    print("Process completed successfully!")
    
except Exception as e:
    print("Error processing EPA data:", e)
finally:
    try:
        if conn:
            conn.close()
            print("Database connection closed")
    except Exception as close_error:
        print(f"Error closing connection: {close_error}")