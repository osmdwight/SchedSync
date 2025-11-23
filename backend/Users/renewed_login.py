import boto3
import json
import hashlib
import hmac
import os

TABLE_NAME = "users"
dynamodb = boto3.resource("dynamodb")
SECRET_KEY = os.environ.get("SECRET_KEY", "my_secret_key")

def hash_password(password):
    return hmac.new(SECRET_KEY.encode(), password.encode(), hashlib.sha256).hexdigest()

def verify_password(entered_password, stored_hash):
    return hmac.compare_digest(hash_password(entered_password), stored_hash)

def build_response(status_code, body_dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST",
            "Access-Control-Allow-Headers": "Content-Type,user_id"
        },
        "body": json.dumps(body_dict)
    }

def lambda_handler(event, context):
    table = dynamodb.Table(TABLE_NAME)
    user_id = event.get("headers", {}).get("user_id")
    if not user_id:
        return build_response(400, {"status": "error", "message": "user_id header is required"})

    body = json.loads(event.get("body", "{}"))
    entered_email = body.get("entered_email")
    entered_password = body.get("entered_password")

    if not entered_email or not entered_password:
        return build_response(400, {"status": "error", "message": "Email and password required."})

    try:
        response = table.get_item(Key={"user_id": user_id})
        item = response.get("Item")
        if not item:
            return build_response(404, {"status": "error", "message": "User not found"})

        stored_email = item.get("email")
        stored_hash = item.get("password_hash")

        if entered_email != stored_email:
            return build_response(401, {"status": "error", "message": "Email does not match."})

        if not verify_password(entered_password, stored_hash):
            return build_response(401, {"status": "error", "message": "Incorrect password."})

        return build_response(200, {"status": "success", "message": "Authentication successful.", "user": {"user_id": item["user_id"], "email": item["email"]}})
    
    except Exception as e:
        return build_response(500, {"status": "error", "message": str(e)})
