import json
import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Submissions")

def build_response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,user_id,user-id"
        },
        "body": json.dumps(body)
    }

def lambda_handler(event, context):

    try:
        headers = {k.lower().replace("-", "_"): v for k, v in (event.get("headers") or {}).items()}
        user_id = headers.get("user_id")

        if not user_id:
            return build_response(400, {"error": "user_id header is required"})

        params = event.get("queryStringParameters") or {}
        task_id = params.get("task_id")

        # CASE 1: Get specific submission
        if task_id:
            resp = table.get_item(Key={"task_id": task_id, "user_id": user_id})
            if "Item" in resp:
                return build_response(200, resp["Item"])
            return build_response(404, {"error": "Submission not found"})

        # CASE 2: Get all submissions for user
        resp = table.scan(
            FilterExpression=Attr("user_id").eq(user_id)
        )

        items = resp.get("Items", [])
        return build_response(200, items)

    except Exception as e:
        return build_response(500, {"error": str(e)})
