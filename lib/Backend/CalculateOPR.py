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
    
    def getTeamScore(alliance, match):
        query = """
            SELECT score 
            FROM TBAMatchScores 
            WHERE match_key = ? AND team_colors = ?
        """
        cursor.execute(query, (match, alliance))
        result = cursor.fetchone()
        team_score = float(result[0]) if result else None
        return team_score

    def calculateOPR(event):
        # Calculate the number of matches (each match has two alliances)
        num_matches = int(getMatchCount() / 2)
        unique_teams = []
        team_index = {}
        teams_per_match = []
        scores_list = []  # one score per alliance per match

        for match in range(1, num_matches + 1):
            match_key = f"{event}_qm{match}"
            match_data = sb.get_match(match_key)
            blue_teams = match_data.get("alliances", {}).get("blue", {}).get("team_keys", [])
            red_teams = match_data.get("alliances", {}).get("red", {}).get("team_keys", [])
            
            # Get scores for blue and red alliances from the database
            scores_list.append(getTeamScore("blue", match))
            scores_list.append(getTeamScore("red", match))
            
            # Add blue alliance teams if not already in the list
            for team in blue_teams:
                if team not in unique_teams:
                    team_index[team] = len(unique_teams)
                    unique_teams.append(team)
            teams_per_match.append(blue_teams)
            
            # Add red alliance teams if not already in the list
            for team in red_teams:
                if team not in unique_teams:
                    team_index[team] = len(unique_teams)
                    unique_teams.append(team)
            teams_per_match.append(red_teams)
        
        # Build a sparse match matrix (rows: alliance instances, columns: teams)
        num_rows = num_matches * 2
        num_cols = len(unique_teams)
        match_matrix = lil_matrix((num_rows, num_cols))
        for i, teams in enumerate(teams_per_match):
            for team in teams:
                match_matrix[i, team_index[team]] = 1
        match_matrix = match_matrix.tocsr()  # Convert to CSR for efficient arithmetic

        # Convert scores list to NumPy array
        scores_array = np.array(scores_list)
        
        # Solve the least squares problem using lsqr (optimized for sparse matrices)
        lsqr_result = lsqr(match_matrix, scores_array)
        all_opr = lsqr_result[0]
        
        # Build a dictionary mapping team to its calculated OPR value
        team_to_opr = {team: all_opr[idx] for team, idx in team_index.items()}
        return team_to_opr

    if __name__ == '__main__':
        event = "2025caoc"
        opr_results = calculateOPR(event)
        print("Calculated OPRs:")
        print(opr_results)

        # Insert the calculated OPR results into the OPR table
        insert_sql = "INSERT INTO dbo.OPR (Team, OPR) VALUES (?, ?)"
        for team, opr in opr_results.items():
            cursor.execute(insert_sql, (team, opr))
        conn.commit()
        print("OPR values inserted into the SQL table.")

finally:
    try:
        conn.close()
    except Exception:
        pass
