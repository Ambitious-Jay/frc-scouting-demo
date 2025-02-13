import hmac
import hashlib
import json
from flask import Flask, request, jsonify, abort
import pyodbc

app = Flask(__name__)

# Allow routes to work with or without trailing slashes.
app.url_map.strict_slashes = False

# Replace with your webhook secret (the one you set when creating the webhook on TBA)
WEBHOOK_SECRET = "e70d31bd8cb94121b2ecf8836b03c1e2"

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

@app.before_request
def log_request_info():
    """Log request method, URL, headers, and body for debugging."""
    print("---- Received Request ----")
    print("Method:", request.method)
    print("URL:", request.url)
    print("Headers:", dict(request.headers))
    print("Body:", request.get_data())
    print("--------------------------")

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
    if message_type == 'upcoming_match':
        process_upcoming_match(message_data)
    
    # (Add additional processing for other message types as needed.)
    
    return jsonify({"status": "success"}), 200

def process_upcoming_match(message_data):
    """
    Example function to process 'upcoming_match' notifications and insert data into SQL Server.
    """
    # Define your SQL Server connection string.
    connection_string = (
        "Driver={SQL Server};"
        "Server=MT-server\\SQLEXPRESS;"  # Fixed duplicate "Server="
        "Database=1148-Scouting;"
        "Trusted_Connection=yes;"
    )
    
    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()
        
        # (Optional) Ensure the table exists.
        create_table_sql = """
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='TBAUpcomingMatches' AND xtype='U')
        BEGIN
            CREATE TABLE TBAUpcomingMatches (
                event_key VARCHAR(50),
                match_key VARCHAR(50),
                event_name VARCHAR(255),
                team_keys VARCHAR(255),
                scheduled_time BIGINT,
                predicted_time BIGINT
            )
        END
        """
        cursor.execute(create_table_sql)
        conn.commit()
        
        # Prepare your insertion statement.
        insert_sql = """
        INSERT INTO TBAUpcomingMatches (event_key, match_key, event_name, team_keys, scheduled_time, predicted_time)
        VALUES (?, ?, ?, ?, ?, ?)
        """
        # Convert team_keys list into a comma-separated string.
        team_keys = ','.join(message_data.get('team_keys', []))
        scheduled_time = message_data.get('scheduled_time')
        predicted_time = message_data.get('predicted_time')
        
        cursor.execute(insert_sql,
                       message_data.get('event_key'),
                       message_data.get('match_key'),
                       message_data.get('event_name'),
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
    app.run(host="0.0.0.0", port=5000, debug=True)
