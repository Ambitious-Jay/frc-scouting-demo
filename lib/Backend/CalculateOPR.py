import statbotics
import numpy as np
import pyodbc
from scipy.sparse import lil_matrix
from scipy.sparse.linalg import lsqr
import urllib.parse

sb = statbotics.Statbotics()

# Connection parameters
username = "1148Robotics"
password = "1148Robotics"
server = "MT-server\\SQLEXPRESS"
database = "1148-Scouting"

# Build the connection string
connection_string = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    # Truncate the OPR table (assumes the table already exists)
    cursor.execute("TRUNCATE TABLE dbo.OPR;")
    conn.commit()

    def getMatchCount():
        query = "SELECT COUNT(*) FROM TBAMatchScores"
        cursor.execute(query)
        result = cursor.fetchone()
        return result[0]
    
    def getTeamScore(metric, alliance, match):
        # The metric parameter should match one of the following columns in TBAMatchScores:
        # score, teleop_trough_count, teleop_reef_bottom_count, teleop_reef_mid_count,
        # teleop_reef_top_count, teleop_coral_count, teleop_coral_points, algae_points,
        # net_algae_count, wall_algae_count.
        query = f"SELECT {metric} FROM TBAMatchScores WHERE match_key = ? AND team_colors = ?"
        cursor.execute(query, (match, alliance))
        result = cursor.fetchone()
        team_score = float(result[0]) if result and result[0] is not None else 0.0
        return team_score

    def calculateAllOPRs(event):
        # Calculate the number of matches (each match has two alliances)
        num_matches = int(getMatchCount() / 2)
        unique_teams = []
        team_index = {}
        teams_per_match = []  # each element is a list of teams for an alliance

        # List of metrics to compute OPR for (separating L2 and L3 from reef counts)
        metrics = [
            "score",
            "teleop_trough_count",
            "teleop_reef_bottom_count",  # L2
            "teleop_reef_mid_count",     # L3
            "teleop_reef_top_count",
            "teleop_coral_count",
            "teleop_coral_points",
            "algae_points",
            "net_algae_count",
            "wall_algae_count"
        ]
        # Prepare a dictionary to store score lists for each metric; one score per alliance instance.
        scores_lists = {m: [] for m in metrics}
        
        for match in range(1, num_matches + 1):
            # Use the string key for statbotics API, but pass the integer for SQL queries.
            match_key = f"{event}_qm{match}"
            match_data = sb.get_match(match_key)
            
            blue_teams = match_data.get("alliances", {}).get("blue", {}).get("team_keys", [])
            red_teams = match_data.get("alliances", {}).get("red", {}).get("team_keys", [])
            
            # Retrieve scores for blue alliance for all metrics using match number for SQL.
            for metric in metrics:
                score = getTeamScore(metric, "blue", match)  # pass match as int
                scores_lists[metric].append(score)
            teams_per_match.append(blue_teams)
            
            # Retrieve scores for red alliance for all metrics using match number for SQL.
            for metric in metrics:
                score = getTeamScore(metric, "red", match)  # pass match as int
                scores_lists[metric].append(score)
            teams_per_match.append(red_teams)
            
            # Update the list of unique teams.
            for team in blue_teams:
                if team not in unique_teams:
                    team_index[team] = len(unique_teams)
                    unique_teams.append(team)
            for team in red_teams:
                if team not in unique_teams:
                    team_index[team] = len(unique_teams)
                    unique_teams.append(team)
        
        # Build a sparse match matrix (rows: alliance instances, columns: teams)
        num_rows = num_matches * 2
        num_cols = len(unique_teams)
        match_matrix = lil_matrix((num_rows, num_cols))
        for i, teams in enumerate(teams_per_match):
            for team in teams:
                match_matrix[i, team_index[team]] = 1
        match_matrix = match_matrix.tocsr()  # Convert to CSR for efficient arithmetic

        # Solve the least squares problem for each metric and collect OPRs.
        opr_results = {}
        for metric in metrics:
            scores_array = np.array(scores_lists[metric])
            lsqr_result = lsqr(match_matrix, scores_array)
            all_opr = lsqr_result[0]
            # For each team, store the OPR value for the current metric.
            for team, idx in team_index.items():
                if team not in opr_results:
                    opr_results[team] = {}
                opr_results[team][metric] = all_opr[idx]
        return opr_results

    if __name__ == '__main__':
        event = "2025cala"
        opr_results = calculateAllOPRs(event)
        print("Calculated OPRs:")
        print(opr_results)

        # Insert the calculated OPR values into the OPR table.
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
                team,
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
