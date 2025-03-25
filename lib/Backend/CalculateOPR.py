import requests
import numpy as np
import pyodbc
from scipy.sparse import lil_matrix
from scipy.sparse.linalg import lsqr

# --- TBA API Configuration ---
TBA_API_KEY = "tcS4SqWjusf1dO6Nqi3kzMO0aHUg9wcJk2MUaPbtH4xnZmWQj5lfW43ab3speDKA"  # Replace with your TBA API key
TBA_BASE_URL = "https://www.thebluealliance.com/api/v3"

# --- SQL Server Configuration ---
username = "1148Robotics"
password = "1148Robotics"
server = "MT-server\\SQLEXPRESS"
database = "1148-Scouting"

# Build connection string
connection_string = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)

# Connect to the database
try:
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    # Truncate OPR table before inserting new data
    cursor.execute("TRUNCATE TABLE dbo.OPR;")
    conn.commit()

    def getMatchCount():
        query = "SELECT COUNT(*) FROM TBAMatchScores"
        cursor.execute(query)
        result = cursor.fetchone()
        return result[0]

    def getTeamScore(metric, alliance, match):
        query = f"SELECT {metric} FROM TBAMatchScores WHERE match_key = ? AND team_colors = ?"
        cursor.execute(query, (match, alliance))
        result = cursor.fetchone()
        return float(result[0]) if result and result[0] is not None else 0.0

    def getTBAEventMatches(event_key):
        """Fetch all qualification matches for an event from The Blue Alliance API."""
        url = f"{TBA_BASE_URL}/event/{event_key}/matches"
        headers = {"X-TBA-Auth-Key": TBA_API_KEY}
        response = requests.get(url, headers=headers)

        if response.status_code != 200:
            print(f"Failed to fetch matches from TBA. Status Code: {response.status_code}")
            return None

        matches = response.json()
        return {match["key"]: match for match in matches if match["comp_level"] == "qm"}

    def calculateAllOPRs(event):
        """Calculate OPRs for an event using data from TBA API."""
        match_data = getTBAEventMatches(event)
        if not match_data:
            print("No match data found.")
            return {}

        num_matches = len(match_data)
        print(f"Total matches found: {num_matches}")

        unique_teams = []
        team_index = {}
        teams_per_match = []  # Stores teams in each alliance

        # Metrics to calculate OPR
        metrics = [
            "score",
            "teleop_trough_count",
            "teleop_reef_bottom_count",
            "teleop_reef_mid_count",
            "teleop_reef_top_count",
            "teleop_coral_count",
            "teleop_coral_points",
            "algae_points",
            "net_algae_count",
            "wall_algae_count"
        ]

        scores_lists = {m: [] for m in metrics}

        for match_key, match in match_data.items():
            match_number = match["match_number"]
            blue_teams = [team.replace("frc", "") for team in match["alliances"]["blue"]["team_keys"]]
            red_teams = [team.replace("frc", "") for team in match["alliances"]["red"]["team_keys"]]

            for metric in metrics:
                score = getTeamScore(metric, "blue", match_number)
                scores_lists[metric].append(score)
            teams_per_match.append(blue_teams)

            for metric in metrics:
                score = getTeamScore(metric, "red", match_number)
                scores_lists[metric].append(score)
            teams_per_match.append(red_teams)

            # Track unique teams
            for team in blue_teams + red_teams:
                if team not in unique_teams:
                    team_index[team] = len(unique_teams)
                    unique_teams.append(team)

        num_rows = num_matches * 2
        num_cols = len(unique_teams)
        match_matrix = lil_matrix((num_rows, num_cols))

        for i, teams in enumerate(teams_per_match):
            for team in teams:
                match_matrix[i, team_index[team]] = 1

        match_matrix = match_matrix.tocsr()

        opr_results = {}
        for metric in metrics:
            scores_array = np.array(scores_lists[metric])
            lsqr_result = lsqr(match_matrix, scores_array)
            all_opr = lsqr_result[0]

            for team, idx in team_index.items():
                if team not in opr_results:
                    opr_results[team] = {}
                opr_results[team][metric] = all_opr[idx]

        return opr_results

    if __name__ == '__main__':
        event = "2025cala"
        opr_results = calculateAllOPRs(event)
        print("Calculated OPRs:", opr_results)

        # Insert results into the database
        insert_sql = """
            INSERT INTO dbo.OPR (
                Team, 
                OPR_Score, 
                OPR_teleop_trough_count, 
                OPR_teleop_reef_bottom_count, 
                OPR_teleop_reef_mid_count, 
                OPR_teleop_reef_top_count, 
                OPR_teleop_coral_count, 
                OPR_teleop_coral_points, 
                OPR_algae_points, 
                OPR_net_algae_count, 
                OPR_wall_algae_count
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        for team, opr_dict in opr_results.items():
            cursor.execute(insert_sql, (
                int(team),  # Convert team number to integer
                opr_dict["score"],
                opr_dict["teleop_trough_count"],
                opr_dict["teleop_reef_bottom_count"],
                opr_dict["teleop_reef_mid_count"],
                opr_dict["teleop_reef_top_count"],
                opr_dict["teleop_coral_count"],
                opr_dict["teleop_coral_points"],
                opr_dict["algae_points"],
                opr_dict["net_algae_count"],
                opr_dict["wall_algae_count"]
            ))
        conn.commit()
        print("OPR values inserted into the SQL table.")

finally:
    try:
        conn.close()
    except Exception:
        pass
