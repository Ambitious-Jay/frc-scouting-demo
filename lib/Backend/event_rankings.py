import requests
import pandas as pd
import urllib.parse
from sqlalchemy import create_engine
import pyodbc
import json

def create_event_rankings_table():
    """
    Ensures the EventRankings table exists in the SQL Server database.
    """
    server = "MT-server\\SQLEXPRESS"  # Named instance
    database = "1148-Scouting"
    username = "1148Robotics"
    password = "1148Robotics"
    
    connection_string = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )
    
    sql_script = """
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='EventRankings' AND xtype='U')
    BEGIN
        CREATE TABLE EventRankings (
            event_key VARCHAR(50) NOT NULL,
            team_key VARCHAR(50) NOT NULL,
            [rank] INT NULL,
            dq INT NULL,
            matches_played INT NULL,
            win_loss_tie VARCHAR(20) NULL
        )
    END
    """
    
    with pyodbc.connect(connection_string) as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql_script)
            conn.commit()
    print("EventRankings table ensured.")

def truncate_event_rankings_table():
    """
    Truncates the EventRankings table.
    """
    server = "MT-server\\SQLEXPRESS"
    database = "1148-Scouting"
    username = "1148Robotics"
    password = "1148Robotics"
    
    connection_string = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )
    
    with pyodbc.connect(connection_string) as conn:
        with conn.cursor() as cursor:
            cursor.execute("TRUNCATE TABLE EventRankings;")
            conn.commit()
    print("EventRankings table truncated.")

def fetch_and_insert_rankings():
    """
    Fetches TBA rankings, processes the data, and inserts it into the EventRankings table.
    """
    # --- Fetch Rankings Data from TBA ---
    api_key = "tcS4SqWjusf1dO6Nqi3kzMO0aHUg9wcJk2MUaPbtH4xnZmWQj5lfW43ab3speDKA"
    event_key = "2025caoc"
    base_url = "https://www.thebluealliance.com/api/v3"
    headers = {"X-TBA-Auth-Key": api_key}
    
    rankings_url = f"{base_url}/event/{event_key}/rankings"
    response = requests.get(rankings_url, headers=headers)
    data = response.json()
    
    rankings_list = data.get('rankings', [])
    if not rankings_list:
        print("No rankings data found.")
        return
    
    df_rankings = pd.DataFrame(rankings_list)
    
    # Flatten the 'record' column into wins, losses, and ties
    if 'record' in df_rankings.columns:
        df_rankings[['wins', 'losses', 'ties']] = df_rankings['record'].apply(
            lambda r: pd.Series([r.get('wins', None), r.get('losses', None), r.get('ties', None)])
            if isinstance(r, dict) else pd.Series([None, None, None])
        )
        df_rankings.drop(columns=['record'], inplace=True)
    
    # Concatenate wins, losses, and ties into a single column
    df_rankings['win_loss_tie'] = df_rankings.apply(
        lambda row: f"{row['wins']}-{row['losses']}-{row['ties']}", axis=1
    )
    
    # Remove unnecessary columns: extra_stats, sort_orders, qual_average, wins, losses, ties
    for col in ['extra_stats', 'sort_orders', 'qual_average', 'wins', 'losses', 'ties']:
        if col in df_rankings.columns:
            df_rankings.drop(columns=[col], inplace=True)
    
    # Ensure the event_key is set for each row
    df_rankings['event_key'] = event_key
    
    print("Fetched Rankings Data:")
    print(df_rankings.head())
    
    # --- Insert Data into SQL Server ---
    server = "MT-server\\SQLEXPRESS"
    database = "1148-Scouting"
    username = "1148Robotics"
    password = "1148Robotics"
    
    params = urllib.parse.quote_plus(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )
    engine = create_engine("mssql+pyodbc:///?odbc_connect=" + params)
    
    # Insert the new data (the table is empty after truncation)
    df_rankings.to_sql('EventRankings', con=engine, if_exists='append', index=False)
    print("Inserted new rankings data into EventRankings table.")

if __name__ == "__main__":
    create_event_rankings_table()
    truncate_event_rankings_table()
    fetch_and_insert_rankings()
