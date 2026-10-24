"""
SmartBus Guardian Flask Backend

Flutter → Flask → SQLite
"""

from flask import Flask, request, jsonify, g
import sqlite3
import os

app = Flask(__name__)

@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, DELETE, OPTIONS"
    return response


@app.route("/<path:path>", methods=["OPTIONS"])
def handle_preflight(path):
    return "", 204


DB_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "smartbus.db"
)


# ============================================================
# HOME
# ============================================================

@app.route("/")
def home():
    return jsonify({
        "message": "SmartBus Guardian Backend is running!"
    })


# ============================================================
# DATABASE
# ============================================================

def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON;")

    return g.db


@app.teardown_appcontext
def close_db(exception=None):
    db = g.pop("db", None)

    if db is not None:
        db.close()


# ============================================================
# REGISTER
# ============================================================

@app.route("/api/register", methods=["POST"])
def register_user():

    data = request.get_json()

    if not data:
        return jsonify({
            "error": "No data received"
        }), 400

    full_name = data.get("full_name", "").strip()
    email = data.get("email", "").strip()
    phone_number = data.get("phone_number", "").strip()
    password_hash = data.get("password_hash", "")

    if not full_name:
        return jsonify({
            "error": "Full name is required"
        }), 400

    if not email:
        return jsonify({
            "error": "Email is required"
        }), 400

    if not phone_number:
        return jsonify({
            "error": "Phone number is required"
        }), 400

    if not password_hash:
        return jsonify({
            "error": "Password is required"
        }), 400

    db = get_db()

    try:

        cur = db.execute(
            """
            INSERT INTO tbl_users
            (
                full_name,
                email,
                phone_number,
                password_hash
            )
            VALUES (?, ?, ?, ?)
            """,
            (
                full_name,
                email,
                phone_number,
                password_hash
            )
        )

        db.commit()

        return jsonify({
            "success": True,
            "user_id": cur.lastrowid,
            "message": "User registered successfully"
        }), 201

    except sqlite3.IntegrityError as e:

        return jsonify({
            "success": False,
            "error": str(e)
        }), 400


# ============================================================
# LOGIN
# ============================================================

@app.route("/api/login", methods=["POST"])
def login_user():

    data = request.get_json()

    if not data:
        return jsonify({
            "error": "No data received"
        }), 400

    identifier = data.get("identifier", "").strip()
    password_hash = data.get("password_hash", "")

    if not identifier:
        return jsonify({
            "error": "Email or phone number is required"
        }), 400

    if not password_hash:
        return jsonify({
            "error": "Password is required"
        }), 400

    db = get_db()

    row = db.execute(
        """
        SELECT
            id,
            full_name,
            email,
            phone_number,
            password_hash
        FROM tbl_users
        WHERE
            (email = ? OR phone_number = ?)
            AND password_hash = ?
        """,
        (
            identifier,
            identifier,
            password_hash
        )
    ).fetchone()

    if row:

        return jsonify({
            "success": True,
            "message": "Login successful",
            "user": {
                "id": row["id"],
                "full_name": row["full_name"],
                "email": row["email"],
                "phone_number": row["phone_number"]
            }
        }), 200

    return jsonify({
        "success": False,
        "error": "Invalid email/phone number or password"
    }), 401


# ============================================================
# START JOURNEY
# ============================================================

@app.route("/api/journey/start", methods=["POST"])
def start_journey():

    data = request.get_json()
    db = get_db()

    cur = db.execute(
        """
        INSERT INTO tbl_journey
        (
            user_id,
            source_location,
            destination_location,
            dest_latitude,
            dest_longitude,
            sleep_mode_enabled,
            start_time
        )
        VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        """,
        (
            data["user_id"],
            data["source_location"],
            data["destination_location"],
            data["dest_latitude"],
            data["dest_longitude"],
            data.get("sleep_mode_enabled", 0)
        )
    )

    db.commit()

    return jsonify({
        "journey_id": cur.lastrowid
    }), 201


# ============================================================
# EMERGENCY CONTACTS
# ============================================================

@app.route("/api/contacts/<int:user_id>", methods=["GET"])
def get_emergency_contacts(user_id):
    db = get_db()
    rows = db.execute(
        """
        SELECT contact_id, user_id, contact_name, contact_phone, relationship
        FROM tbl_emergency_contact
        WHERE user_id = ?
        ORDER BY contact_id DESC
        """,
        (user_id,)
    ).fetchall()

    contacts = [
        {
            "contact_id": row["contact_id"],
            "user_id": row["user_id"],
            "contact_name": row["contact_name"],
            "contact_phone": row["contact_phone"],
            "relationship": row["relationship"] or ""
        }
        for row in rows
    ]

    return jsonify({"success": True, "contacts": contacts}), 200


@app.route("/api/contacts", methods=["POST"])
def add_emergency_contact():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data received"}), 400

    user_id = data.get("user_id")
    contact_name = data.get("contact_name", "").strip()
    contact_phone = data.get("contact_phone", "").strip()
    relationship = data.get("relationship", "Emergency Contact").strip()

    if not user_id or not contact_name or not contact_phone:
        return jsonify({"error": "user_id, contact_name, and contact_phone are required"}), 400

    if is_emergency_helpline_number(contact_phone):
        return jsonify({
            "success": False,
            "error": "Emergency helpline numbers cannot be saved as trusted contacts"
        }), 400

    db = get_db()
    cur = db.execute(
        """
        INSERT INTO tbl_emergency_contact
        (user_id, contact_name, contact_phone, relationship)
        VALUES (?, ?, ?, ?)
        """,
        (user_id, contact_name, contact_phone, relationship)
    )
    db.commit()

    return jsonify({
        "success": True,
        "contact_id": cur.lastrowid,
        "message": "Emergency contact added successfully"
    }), 201


@app.route("/api/contacts/<int:contact_id>", methods=["DELETE"])
def delete_emergency_contact(contact_id):
    db = get_db()
    db.execute("DELETE FROM tbl_emergency_contact WHERE contact_id = ?", (contact_id,))
    db.commit()
    return jsonify({"success": True, "message": "Emergency contact deleted"}), 200


def is_emergency_helpline_number(phone_number):
    digits = "".join(ch for ch in str(phone_number) if ch.isdigit())
    helpline_numbers = {"112", "100", "1091", "108", "911", "999", "000"}
    if digits in helpline_numbers:
        return True
    if digits.startswith("91") and digits[2:] in helpline_numbers:
        return True
    if digits.startswith("0091") and digits[4:] in helpline_numbers:
        return True
    return False


@app.route("/api/sms/send", methods=["POST"])
def send_sms_message():
    data = request.get_json(silent=True) or {}
    phones = data.get("phones") or data.get("phone_numbers") or []
    message = str(data.get("message", "") or "").strip()

    if not phones or not message:
        return jsonify({
            "success": False,
            "fallback": "device",
            "error": "phones and message are required"
        }), 400

    normalized_numbers = []
    for raw_phone in phones:
        clean_phone = "".join(ch for ch in str(raw_phone) if ch.isdigit() or ch == "+")
        if clean_phone and not is_emergency_helpline_number(clean_phone):
            normalized_numbers.append(clean_phone)

    if not normalized_numbers:
        return jsonify({
            "success": False,
            "fallback": "none",
            "error": "no eligible trusted contact numbers were provided; emergency helplines are excluded"
        }), 400

    account_sid = os.getenv("TWILIO_ACCOUNT_SID")
    auth_token = os.getenv("TWILIO_AUTH_TOKEN")
    from_number = os.getenv("TWILIO_FROM_NUMBER")

    if not (account_sid and auth_token and from_number):
        return jsonify({
            "success": False,
            "fallback": "device",
            "backend": "not_configured",
            "message": "Backend SMS gateway is not configured. Device SMS fallback will be used."
        }), 200

    try:
        from twilio.rest import Client

        client = Client(account_sid, auth_token)
        for phone_number in normalized_numbers:
            client.messages.create(
                body=message,
                from_=from_number,
                to=phone_number,
            )

        return jsonify({
            "success": True,
            "fallback": "none",
            "backend": "twilio",
            "sent_to": len(normalized_numbers),
            "message": "Emergency SMS sent successfully via backend"
        }), 200
    except Exception as exc:
        return jsonify({
            "success": False,
            "fallback": "device",
            "backend": "twilio",
            "error": str(exc)
        }), 502


# ============================================================
# SOS
# ============================================================

@app.route("/api/sos", methods=["POST"])
def raise_sos():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data received"}), 400

    db = get_db()
    user_id = data.get("user_id", 1)
    journey_id = data.get("journey_id")
    lat = data.get("latitude", 0.0)
    lng = data.get("longitude", 0.0)

    # If journey_id is not provided or 0, ensure or create a dummy/active journey record
    if not journey_id:
        # Check if user has an ongoing journey
        ongoing = db.execute(
            "SELECT journey_id FROM tbl_journey WHERE user_id = ? AND journey_status = 'ONGOING' ORDER BY journey_id DESC LIMIT 1",
            (user_id,)
        ).fetchone()
        if ongoing:
            journey_id = ongoing["journey_id"]
        else:
            # Create a general emergency journey record if required for FK constraint
            cur_j = db.execute(
                """
                INSERT INTO tbl_journey (user_id, source_location, destination_location, dest_latitude, dest_longitude, start_time, journey_status)
                VALUES (?, 'Current Location', 'Emergency SOS Point', ?, ?, CURRENT_TIMESTAMP, 'ONGOING')
                """,
                (user_id, lat, lng)
            )
            journey_id = cur_j.lastrowid

    cur = db.execute(
        """
        INSERT INTO tbl_sos_alert
        (
            user_id,
            journey_id,
            latitude,
            longitude,
            status
        )
        VALUES (?, ?, ?, ?, 'SENT')
        """,
        (
            user_id,
            journey_id,
            lat,
            lng
        )
    )

    db.commit()

    return jsonify({
        "success": True,
        "sos_id": cur.lastrowid,
        "journey_id": journey_id,
        "status": "SENT",
        "message": "Emergency SOS broadcasted successfully"
    }), 201


@app.route("/api/sos/<int:user_id>", methods=["GET"])
def get_sos_history(user_id):
    db = get_db()
    rows = db.execute(
        """
        SELECT sos_id, user_id, journey_id, latitude, longitude, sent_at, status
        FROM tbl_sos_alert
        WHERE user_id = ?
        ORDER BY sent_at DESC
        """,
        (user_id,)
    ).fetchall()

    alerts = [
        {
            "sos_id": row["sos_id"],
            "user_id": row["user_id"],
            "journey_id": row["journey_id"],
            "latitude": row["latitude"],
            "longitude": row["longitude"],
            "sent_at": row["sent_at"],
            "status": row["status"]
        }
        for row in rows
    ]

    return jsonify({"success": True, "alerts": alerts}), 200


# ============================================================
# RUN SERVER
# ============================================================

if __name__ == "__main__":
    app.run(
        debug=True,
        host="0.0.0.0",
        port=5000
    )