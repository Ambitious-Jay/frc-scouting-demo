import hmac
import hashlib
import json
from flask import Flask, request, jsonify, abort
import pyodbc

# $ ngrok http 50000

app = Flask(__name__)

# Allow routes to work with or without trailing slashes.
app.url_map.strict_slashes = False

# Replace with your webhook secret (the one you set when creating the webhook on TBA)
WEBHOOK_SECRET = "f63be5cf91694dc29d109b2a341e5c71"

def verify_signature(payload: bytes, signature: str) -> bool:
    """
    Verify the HMAC signature sent by TBA.
    The signature is calculated as: HMAC_SHA256(secret, payload)
    """
    computed_signature = hmac.new(
        WEBHOOK_SECRET.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(computed_signature, signature)

# @app.before_request
# def log_request_info():
#     """Log request method, URL, headers, and body for debugging."""
#     print("---- Received Request ----")
#     print("Method:", request.method)
#     print("URL:", request.url)
#     print("Headers:", dict(request.headers))
#     print("Body:", request.get_data())
#     print("--------------------------")

@app.route('/webhook', methods=['GET'])
def health_check():
    """Simple GET endpoint for health checking."""
    return "Server is up", 200

@app.route('/webhook', methods=['POST'])
def webhook():
    # Retrieve the raw POST data (as bytes) and the provided HMAC header.
    payload = request.get_data()
    signature = request.headers.get('X-TBA-HMAC')
    
    if not signature:
        abort(400, description="Missing X-TBA-HMAC header.")
    
    # Verify the signature.
    if not verify_signature(payload, signature):
        abort(400, description="Invalid signature.")
    
    # Parse JSON payload.
    try:
        data = json.loads(payload.decode('utf-8'))
    except Exception as e:
        abort(400, description="Invalid JSON payload.")
    
    message_type = data.get('message_type')
    message_data = data.get('message_data')
    
    print(f"Received webhook: {message_type}")
    print(json.dumps(message_data, indent=2))
    
    # Process the verification message.
    if message_type == 'verification':
        verification_key = message_data.get('verification_key')
        print("Verification request received. Verification key:", verification_key)
        # After receiving this, verify the webhook in your TBA account.
        return jsonify({"status": "verification received", "verification_key": verification_key})
    
    # Process a ping notification.
    if message_type == 'ping':
        print("Ping received.")
        return jsonify({"status": "pong"})
    
    # Process upcoming match notifications.
    # if message_type == 'upcoming_match':
    #     process_upcoming_match_save(message_data)
        
    if message_type == 'match_score':
        process_match_score_save(message_data, "red")
        process_match_score_save(message_data, "blue")      
        print("Match score received.")     
    # (Add additional processing for other message types as needed.)
    
    return jsonify({"status": "success"}), 200

# def process_upcoming_match(message_data):
#     """
#     Example function to process 'upcoming_match' notifications and print data.
#     """
#     # Convert team_keys list into a comma-separated string.
#     team_keys = ','.join(message_data.get('team_keys', []))
#     scheduled_time = message_data.get('scheduled_time')
#     predicted_time = message_data.get('predicted_time')
    
#     print("Upcoming match data:")
#     print(f"Event Key: {message_data.get('event_key')}")
#     print(f"Match Key: {message_data.get('match_key')}")
#     print(f"Event Name: {message_data.get('event_name')}")
#     print(f"Team Keys: {team_keys}")
#     print(f"Scheduled Time: {scheduled_time}")
#     print(f"Predicted Time: {predicted_time}")

def process_match_score_save(message_data, team_color):
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
        
        # Normalize the input data: if message_data contains a nested "message_data" key, use it.
        data = message_data.get("message_data", message_data)
        match_key = data.get("match_key")
        if match_key and "_qm" in match_key:
            match_key = match_key.split("_qm")[-1]
        team_key = data.get("team_key")
        
        # Get match and alliance details
        match = data.get("match", {})
        alliances = match.get("alliances", {})
        
        # Determine alliance color: start with the provided team_color and override if team_key is found in one of the alliances.
        alliance_color = team_color
        for color, alliance in alliances.items():
            if team_key in alliance.get("team_keys", []):
                alliance_color = color
                break
        
        if alliance_color is None:
            print("Team key not found in any alliance.")
            return

        # Get alliance details and create a comma-separated team_keys string.
        alliance = alliances.get(alliance_color, {})
        team_keys_str = ','.join(alliance.get("team_keys", []))
        
        # Check if record already exists using the correctly retrieved match_key and team_keys_str.
        check_sql = "SELECT COUNT(*) FROM TBAMatchScores WHERE match_key = ? AND team_keys = ?"
        cursor.execute(check_sql, match_key, team_keys_str)
        count = cursor.fetchone()[0]
        if count > 0:
            print("Record with the same match_key and team_keys already exists. Skipping insertion.")
            return
        
        # Now extract score breakdown and other details.
        score_breakdown = match.get("score_breakdown", {}).get(alliance_color, {})

        # Auto and end-game robot actions
        auto_line_robot_1 = score_breakdown.get("autoLineRobot1")
        auto_line_robot_2 = score_breakdown.get("autoLineRobot2")
        auto_line_robot_3 = score_breakdown.get("autoLineRobot3")
        end_game_robot_1 = score_breakdown.get("endGameRobot1")
        end_game_robot_2 = score_breakdown.get("endGameRobot2")
        end_game_robot_3 = score_breakdown.get("endGameRobot3")

        # Extract auto reef scoring data (top, mid and bottom rows)
        autoReef = score_breakdown.get("autoReef", {})
        reef_top_auto_nodes = autoReef.get("topRow", {})
        reef_mid_auto_nodes = autoReef.get("midRow", {})
        reef_bottom_auto_nodes = autoReef.get("botRow", {})

        reef_top_auto_nodes_A = reef_top_auto_nodes.get("nodeA")
        reef_top_auto_nodes_B = reef_top_auto_nodes.get("nodeB")
        reef_top_auto_nodes_C = reef_top_auto_nodes.get("nodeC")
        reef_top_auto_nodes_D = reef_top_auto_nodes.get("nodeD")
        reef_top_auto_nodes_E = reef_top_auto_nodes.get("nodeE")
        reef_top_auto_nodes_F = reef_top_auto_nodes.get("nodeF")
        reef_top_auto_nodes_G = reef_top_auto_nodes.get("nodeG")
        reef_top_auto_nodes_H = reef_top_auto_nodes.get("nodeH")
        reef_top_auto_nodes_I = reef_top_auto_nodes.get("nodeI")
        reef_top_auto_nodes_J = reef_top_auto_nodes.get("nodeJ")
        reef_top_auto_nodes_K = reef_top_auto_nodes.get("nodeK")
        reef_top_auto_nodes_L = reef_top_auto_nodes.get("nodeL")

        reef_mid_auto_nodes_A = reef_mid_auto_nodes.get("nodeA")
        reef_mid_auto_nodes_B = reef_mid_auto_nodes.get("nodeB")
        reef_mid_auto_nodes_C = reef_mid_auto_nodes.get("nodeC")
        reef_mid_auto_nodes_D = reef_mid_auto_nodes.get("nodeD")
        reef_mid_auto_nodes_E = reef_mid_auto_nodes.get("nodeE")
        reef_mid_auto_nodes_F = reef_mid_auto_nodes.get("nodeF")
        reef_mid_auto_nodes_G = reef_mid_auto_nodes.get("nodeG")
        reef_mid_auto_nodes_H = reef_mid_auto_nodes.get("nodeH")
        reef_mid_auto_nodes_I = reef_mid_auto_nodes.get("nodeI")
        reef_mid_auto_nodes_J = reef_mid_auto_nodes.get("nodeJ")
        reef_mid_auto_nodes_K = reef_mid_auto_nodes.get("nodeK")
        reef_mid_auto_nodes_L = reef_mid_auto_nodes.get("nodeL")

        reef_bottom_auto_nodes_A = reef_bottom_auto_nodes.get("nodeA")
        reef_bottom_auto_nodes_B = reef_bottom_auto_nodes.get("nodeB")
        reef_bottom_auto_nodes_C = reef_bottom_auto_nodes.get("nodeC")
        reef_bottom_auto_nodes_D = reef_bottom_auto_nodes.get("nodeD")
        reef_bottom_auto_nodes_E = reef_bottom_auto_nodes.get("nodeE")
        reef_bottom_auto_nodes_F = reef_bottom_auto_nodes.get("nodeF")
        reef_bottom_auto_nodes_G = reef_bottom_auto_nodes.get("nodeG")
        reef_bottom_auto_nodes_H = reef_bottom_auto_nodes.get("nodeH")
        reef_bottom_auto_nodes_I = reef_bottom_auto_nodes.get("nodeI")
        reef_bottom_auto_nodes_J = reef_bottom_auto_nodes.get("nodeJ")
        reef_bottom_auto_nodes_K = reef_bottom_auto_nodes.get("nodeK")
        reef_bottom_auto_nodes_L = reef_bottom_auto_nodes.get("nodeL")

        # Auto reef counts
        auto_trough_count = autoReef.get("trough")
        auto_reef_bottom_count = autoReef.get("tba_botRowCount")
        auto_reef_mid_count = autoReef.get("tba_midRowCount")
        auto_reef_top_count = autoReef.get("tba_topRowCount")

        # Other auto scoring values
        auto_coral_count = score_breakdown.get("autoCoralCount")
        auto_coral_points = score_breakdown.get("autoCoralPoints")
        auto_mobility_points = score_breakdown.get("autoMobilityPoints")
        auto_points = score_breakdown.get("autoPoints")

        # Extract teleop reef scoring data and counts
        teleopReef = score_breakdown.get("teleopReef", {})
        teleop_trough_count = teleopReef.get("trough")
        teleop_reef_bottom_count = teleopReef.get("tba_botRowCount")
        teleop_reef_mid_count = teleopReef.get("tba_midRowCount")
        teleop_reef_top_count = teleopReef.get("tba_topRowCount")

        # Teleop coral values
        teleop_coral_count = score_breakdown.get("teleopCoralCount")
        teleop_coral_points = score_breakdown.get("teleopCoralPoints")

        # Other teleop and end-game values
        algae_points = score_breakdown.get("algaePoints")
        net_algae_count = score_breakdown.get("netAlgaeCount")
        wall_algae_count = score_breakdown.get("wallAlgaeCount")
        end_game_barge_points = score_breakdown.get("endGameBargePoints")

        # Bonus and penalty fields
        auto_bonus_achieved = score_breakdown.get("autoBonusAchieved")
        coral_bonus_achieved = score_breakdown.get("coralBonusAchieved")
        barge_bonus_achieved = score_breakdown.get("bargeBonusAchieved")
        coopertition_criteria_met = score_breakdown.get("coopertitionCriteriaMet")
        foul_count = score_breakdown.get("foulCount")
        tech_foul_count = score_breakdown.get("techFoulCount")
        adjust_points = score_breakdown.get("adjustPoints")
        foul_points = score_breakdown.get("foulPoints")
        ranking_points = score_breakdown.get("rp")
        total_points = score_breakdown.get("totalPoints")
        
        insert_sql = """
            INSERT INTO TBAMatchScores (
                match_key, team_keys, score,
                auto_line_robot_1, auto_line_robot_2, auto_line_robot_3,
                end_game_robot_1, end_game_robot_2, end_game_robot_3,
                reef_top_auto_nodes_A, reef_top_auto_nodes_B, reef_top_auto_nodes_C, reef_top_auto_nodes_D,
                reef_top_auto_nodes_E, reef_top_auto_nodes_F, reef_top_auto_nodes_G, reef_top_auto_nodes_H,
                reef_top_auto_nodes_I, reef_top_auto_nodes_J, reef_top_auto_nodes_K, reef_top_auto_nodes_L,
                reef_mid_auto_nodes_A, reef_mid_auto_nodes_B, reef_mid_auto_nodes_C, reef_mid_auto_nodes_D,
                reef_mid_auto_nodes_E, reef_mid_auto_nodes_F, reef_mid_auto_nodes_G, reef_mid_auto_nodes_H,
                reef_mid_auto_nodes_I, reef_mid_auto_nodes_J, reef_mid_auto_nodes_K, reef_mid_auto_nodes_L,
                reef_bottom_auto_nodes_A, reef_bottom_auto_nodes_B, reef_bottom_auto_nodes_C, reef_bottom_auto_nodes_D,
                reef_bottom_auto_nodes_E, reef_bottom_auto_nodes_F, reef_bottom_auto_nodes_G, reef_bottom_auto_nodes_H,
                reef_bottom_auto_nodes_I, reef_bottom_auto_nodes_J, reef_bottom_auto_nodes_K, reef_bottom_auto_nodes_L,
                auto_trough_count, auto_reef_bottom_count, auto_reef_mid_count, auto_reef_top_count,
                auto_coral_count, auto_coral_points, auto_mobility_points, auto_points,
                teleop_trough_count, teleop_reef_bottom_count, teleop_reef_mid_count, teleop_reef_top_count,
                teleop_coral_count, teleop_coral_points, algae_points, net_algae_count, wall_algae_count,
                end_game_barge_points, auto_bonus_achieved, coral_bonus_achieved, barge_bonus_achieved,
                coopertition_criteria_met, foul_count, tech_foul_count, adjust_points, foul_points,
                ranking_points, total_points, team_colors
            ) VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
            )
        """
        
        cursor.execute(insert_sql,
                       match_key, team_keys_str, alliance.get("score"),
                       auto_line_robot_1, auto_line_robot_2, auto_line_robot_3,
                       end_game_robot_1, end_game_robot_2, end_game_robot_3,
                       reef_top_auto_nodes_A, reef_top_auto_nodes_B, reef_top_auto_nodes_C, reef_top_auto_nodes_D,
                       reef_top_auto_nodes_E, reef_top_auto_nodes_F, reef_top_auto_nodes_G, reef_top_auto_nodes_H,
                       reef_top_auto_nodes_I, reef_top_auto_nodes_J, reef_top_auto_nodes_K, reef_top_auto_nodes_L,
                       reef_mid_auto_nodes_A, reef_mid_auto_nodes_B, reef_mid_auto_nodes_C, reef_mid_auto_nodes_D,
                       reef_mid_auto_nodes_E, reef_mid_auto_nodes_F, reef_mid_auto_nodes_G, reef_mid_auto_nodes_H,
                       reef_mid_auto_nodes_I, reef_mid_auto_nodes_J, reef_mid_auto_nodes_K, reef_mid_auto_nodes_L,
                       reef_bottom_auto_nodes_A, reef_bottom_auto_nodes_B, reef_bottom_auto_nodes_C, reef_bottom_auto_nodes_D,
                       reef_bottom_auto_nodes_E, reef_bottom_auto_nodes_F, reef_bottom_auto_nodes_G, reef_bottom_auto_nodes_H,
                       reef_bottom_auto_nodes_I, reef_bottom_auto_nodes_J, reef_bottom_auto_nodes_K, reef_bottom_auto_nodes_L,
                       auto_trough_count, auto_reef_bottom_count, auto_reef_mid_count, auto_reef_top_count,
                       auto_coral_count, auto_coral_points, auto_mobility_points, auto_points,
                       teleop_trough_count, teleop_reef_bottom_count, teleop_reef_mid_count, teleop_reef_top_count,
                       teleop_coral_count, teleop_coral_points, algae_points, net_algae_count, wall_algae_count,
                       end_game_barge_points, auto_bonus_achieved, coral_bonus_achieved, barge_bonus_achieved,
                       coopertition_criteria_met, foul_count, tech_foul_count, adjust_points, foul_points,
                       ranking_points, total_points, alliance_color)
        conn.commit()
        print("Upcoming match inserted into SQL Server.")
    except Exception as e:
        print("Error processing upcoming_match:", e)
    finally:
        try:
            conn.close()
        except Exception:
            pass


def process_upcoming_match(message_data):
    """
    Example function to process 'upcoming_match' notifications and print data.
    """
    # Convert team_keys list into a comma-separated string.
    team_keys = ','.join(message_data.get('team_keys', []))
    scheduled_time = message_data.get('scheduled_time')
    predicted_time = message_data.get('predicted_time')
    
    print("Upcoming match data:")
    print(f"Event Key: {message_data.get('event_key')}")
    print(f"Match Key: {message_data.get('match_key')}")
    print(f"Event Name: {message_data.get('event_name')}")
    print(f"Team Keys: {team_keys}")
    print(f"Scheduled Time: {scheduled_time}")
    print(f"Predicted Time: {predicted_time}")


def process_upcoming_match_save(message_data):
    """
    Example function to process 'upcoming_match' notifications and insert data into SQL Server.
    """
    # Define your SQL Server connection string.
    server = 'MT-server'
    database = '1148-Scouting'
    username = '1148Robotics'
    password = '1148Robotics'

    # Create the connection string
    connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
    
    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()
        
        # (Optional) Ensure the table exists.
        # create_table_sql = """
        # IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='TBAUpcomingMatches' AND xtype='U')
        # BEGIN
        #     CREATE TABLE TBAUpcomingMatches (
        #         event_key VARCHAR(50),
        #         match_key VARCHAR(50),
        #         event_name VARCHAR(255),
        #         team_keys VARCHAR(255),
        #         scheduled_time BIGINT,
        #         predicted_time BIGINT
        #     )
        # END
        # """
        # cursor.execute(create_table_sql)
        # conn.commit()
        
        # Prepare your insertion statement.
        # Check if a record with the same match_key already exists.
        check_sql = "SELECT COUNT(*) FROM TBAUpcomingMatches WHERE match_key = ?"
        cursor.execute(check_sql, message_data.get('match_key'))
        count = cursor.fetchone()[0]
        
        if count > 0:
            print("Record with the same match_key already exists. Skipping insertion.")
            return
        
        insert_sql = """
        INSERT INTO TBAUpcomingMatches (event_key, match_key, event_name, team_keys, scheduled_time, predicted_time)
        VALUES (?, ?, ?, ?, ?, ?)
        """
        # Convert team_keys list into a comma-separated string.
        team_keys = ','.join(message_data.get('team_keys', []))
        scheduled_time = message_data.get('scheduled_time')
        predicted_time = message_data.get('predicted_time')
        match_key = message_data.get('match_key')
        if match_key and "_qm" in match_key:
            match_key = match_key.split("_qm")[-1]
        
        cursor.execute(insert_sql,
                       message_data.get('event_key'),
                       message_data.get('match_key'),
                       match_key,
                       team_keys,
                       scheduled_time,
                       predicted_time)
        conn.commit()
        print("Upcoming match inserted into SQL Server.")
    except Exception as e:
        print("Error processing upcoming_match:", e)
    finally:
        try:
            conn.close()
        except Exception:
            pass


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=50000, debug=True)