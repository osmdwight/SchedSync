import json
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Exams")

# UNIVERSAL CORS HEADERS (use everywhere)
CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,user-id,user_id",
    "Access-Control-Allow-Methods": "OPTIONS,GET,POST,PUT,DELETE"
}

def lambda_handler(event, context):

    print("EVENT RECEIVED:", json.dumps(event))

    raw_headers = event.get("headers", {}) or {}

    # Normalize headers (support BOTH user-id & user_id)
    normalized = {
        k.lower().replace('-', '_'): v
        for k, v in raw_headers.items()
    }

    user_id = None

    # From query string
    if event.get("queryStringParameters"):
        user_id = event["queryStringParameters"].get("user_id")

    # From headers (after normalization)
    if not user_id:
        user_id = normalized.get("user_id")

    # From body JSON
    if not user_id and event.get("body"):
        try:
            body = json.loads(event["body"])
            user_id = body.get("user_id")
        except:
            pass

    if not user_id:
        return {
            "statusCode": 400,
            "headers": CORS,
            "body": json.dumps({"error": "user_id is required"})
        }

    # Fetch Exams
    response = table.query(
        IndexName="user_id-index",
        KeyConditionExpression=Key("user_id").eq(user_id)
    )

    return {
        "statusCode": 200,
        "headers": CORS,
        "body": json.dumps(response["Items"])
    }
