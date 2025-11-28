import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("CLASSES")


def build_response(status_code, body_dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,user_id"
        },
        "body": json.dumps(body_dict)
    }


def lambda_handler(event, context):
    try:
        user_id = None
        if event.get("headers"):
            user_id = event["headers"].get("user_id")

        if not user_id:
            return build_response(400, {
                "status": "error",
                "message": "user_id header is required"
            })

        class_code = None
        params = event.get("queryStringParameters") or {}
        class_code = params.get("class_code")

        if not class_code:
            body = event.get("body")
            if body:
                data = json.loads(body) if isinstance(body, str) else body
                class_code = data.get("class_code")

        if not class_code:
            return build_response(400, {
                "status": "error",
                "message": "class_code is required in query parameters or request body."
            })

        try:
            response = table.get_item(
                Key={
                    "class_code": class_code,
                    "user_id": user_id
                }
            )

            if "Item" not in response:
                return build_response(404, {
                    "status": "error",
                    "message": "Class not found for this user."
                })

        except ClientError as e:
            return build_response(500, {
                "status": "error",
                "message": f"Error checking class: {str(e)}"
            })

        table.delete_item(
            Key={
                "class_code": class_code,
                "user_id": user_id
            }
        )

        return build_response(200, {
            "status": "success",
            "message": "Class deleted successfully.",
            "deleted_class": {
                "user_id": user_id,
                "class_code": class_code
            }
        })

    except ClientError as e:
        if e.response["Error"]["Code"] == "ValidationException":
            return build_response(400, {
                "status": "error",
                "message": "Invalid key format."
            })
        else:
            return build_response(500, {
                "status": "error",
                "message": e.response["Error"]["Message"]
            })
    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })
