import boto3
import json

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

dynamodb = boto3.resource("dynamodb")
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

        existUser = table.get_item(Key={"user_id": user_id}).get("Item")
        if not existUser:
            return build_response(404, {
                "status": "error",
                "message": f"User Not Found\n{str(e)}"
            })
        
        try:
            table.delete_item(Key={"user_id": user_id})
        except Exception as e:
            return build_response(500, {
                "status": "error",
                "message": f"DynamoDB delete failed: {str(e)}"
            })
        
        return build_response(200, {
            "status": "success",
            "message": f"User {user_id} was deleted sucessfully!"
        })
    
    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })