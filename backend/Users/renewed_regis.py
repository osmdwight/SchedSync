import boto3
import json
import hashlib
import hmac
import os
import uuid

SECRET_KEY = os.environ.get("SECRET_KEY", "my_secret_key")

def hash_password(password: str) -> str:
    return hmac.new(SECRET_KEY.encode(), password.encode(), hashlib.sha256).hexdigest()

def build_response(status_code, body_dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps(body_dict)
    }
dynamodb = boto3.resource("dynamodb")
TABLE_NAME = "users"

def lambda_handler(event, context):
    try:
        user_id = uuid.uuid4()
        body = event.get("body")
        if body is None:
            return build_response(400, {
                "status": "error",
                "message": "Request body is missing."
            })
        if isinstance(body, str):
            data = json.loads(body)
        else:
            data = body
        
        required_fields = [
            "email",
            "first_name",
            "last_name",
            "image",
            "password_hash",
            "theme_preference"
        ]
        missing = [f for f in required_fields if f not in data]
        if missing:
            return build_response(400, {
                "status": "error",
                "message": "Missing fields: " + ", ".join(missing)
            })
        items = {
            "user_id": user_id, 
            "email": data["email"],
            "first_name": data["first_name"],
            "last_name": data["last_name"],
            "image": data["image"],
            "password_hash": hash_password(data["password_hash"]),
            "theme_preference": data["theme_preference"],
        }
        try:
            table = dynamodb.Table(TABLE_NAME)
            table.put_item(Item=items)
            return build_response(200, {
                "status": "success",
                "data": items
            })
        except Exception as e:
            return build_response(500, {
                "status": "error",
                "message": f"error DynamoDB insert failed: {str(e)}"
            })
        
    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })
