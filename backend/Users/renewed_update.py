import boto3
import base64
import uuid
import json
import hashlib
import hmac
import os

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
            "Access-Control-Allow-Headers": "Content-Type,user_id"
        },
        "body": json.dumps(body_dict)
    }

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

BUCKET_NAME = "user-images-loc"
TABLE_NAME = "users"

def lambda_handler(event, context):
    try:
        table = dynamodb.Table(TABLE_NAME)

        user_id = event.get("headers", {}).get("user_id")
        if not user_id:
            return build_response(400, {
                "status": "error",
                "message": "user-id header is required"
            })

        body = event.get("body")
        if not body:
            return build_response(400, {"status": "error", "message": "Request body is missing."})

        data = json.loads(body) if isinstance(body, str) else body

        image_base64 = data.get("image_base64")
        image_name = data.get("image_name")
        image_type = data.get("image_type")

        if image_base64:
            try:
               image_bytes = base64.b64decode(image_base64)
               file_name = f"{uuid.uuid4()}_{image_name}"

               s3.put_object(
                   Bucket=BUCKET_NAME,
                   Key=f"characters/{file_name}",
                   Body=image_bytes,
                   ContentType=image_type
               )

               image_url = f"https://{BUCKET_NAME}.s3.ap-southeast-2.amazonaws.com/characters/{file_name}"

               data["image"] = image_url

            except Exception as e:
                return build_response(500, {
                    "status": "error",
                    "message": f"S3 upload failed: {str(e)}"
                })

        updatable_fields = [
            "email",
            "first_name",
            "last_name",
            "image",
            "password_hash",
            "theme_preference"
        ]

        update_expression = []
        expression_attribute_values = {}

        for field in updatable_fields:
            if field in data:
                if field == "password_hash":
                    data[field] = hash_password(data[field])
                update_expression.append(f"{field} = :{field}")
                expression_attribute_values[f":{field}"] = data[field]

        if not update_expression:
            return build_response(400, {
                "status": "error",
                "message": "No valid fields provided to update."
            })

        update_expr = "SET " + ", ".join(update_expression)

        response = table.update_item(
            Key={"user_id": user_id},
            UpdateExpression=update_expr,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )

        updated_item = response.get("Attributes", {})

        return build_response(200, {
            "status": "success",
            "message": "User updated successfully",
            "updated": updated_item
        })

    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })
