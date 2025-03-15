# Pip install statbotics PLEASEEE and the rest of the imports
import statbotics
import requests
import pyodbc

curEvent = "2025cala"

def TBA_AddressFetcher(path):
    request_url = "https://www.thebluealliance.com/api/v3/" + path
    payload = {"X-TBA-Auth-Key": "tcS4SqWjusf1dO6Nqi3kzMO0aHUg9wcJk2MUaPbtH4xnZmWQj5lfW43ab3speDKA"}
    req = requests.get(request_url, params=payload).json()
    return req

def TBA_EventOPRs(event):     
    if TBA_AddressFetcher("event/"+event+"/oprs") is not None:         
        return TBA_AddressFetcher("event/"+event+"/oprs")
    
Teams = list(TBA_EventOPRs(curEvent)['ccwms'].keys())
    
print(Teams)

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
      
      
server = 'MT-server'
database = '1148-Scouting'
username = '1148Robotics'
password = '1148Robotics'

# Create the connection string
connection_string = (
    f'DRIVER={{ODBC Driver 17 for SQL Server}};'
    f'SERVER={server};'
    f'DATABASE={database};'
    f'UID={username};'
    f'PWD={password}'
)

try:
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    
    cursor.execute("TRUNCATE TABLE StatsboticsEPA")
    conn.commit()
    
    for i in range(len(Teams)):
        team = Teams[i].replace("frc", "")
        team = int(team)
        epa = (sb.get_team_event(team, curEvent).get('epa').get('breakdown'))
        team_data = (sb.get_team(team))
        name = (team_data.get('name'))
        # print(name)
        total = (epa.get('total_points'))
        # print(total)
        auto = (epa.get('auto_points'))
        # print(auto)
        teleop = (epa.get('teleop_points'))
        # print(teleop)
        endgame = (epa.get('endgame_points'))
        # print(endgame)
        current = (team_data.get('norm_epa').get('current'))
        # print(current)
        recent = (team_data.get('norm_epa').get('recent'))
        # print(recent)
        mean = (team_data.get('norm_epa').get('mean'))
        # print(mean)
        max = (team_data.get('norm_epa').get('max'))
        # print(max)
        saveEPA(team, name, total, auto, teleop, endgame, current, recent, mean, max)
    
    
except Exception as e:
    print("Error processing EPA data:", e)
finally:
    try:
        conn.close()
    except Exception:
        pass