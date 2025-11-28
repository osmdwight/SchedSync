import json
import boto3
import uuid
from botocore.exceptions import ClientError
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Submissions")

def lambda_handler(event, context):


    cors = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,user_id,user-id",
        "Access-Control-Allow-Methods": "OPTIONS,POST,"
    }


    if event.get("httpMethod") == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": cors,
            "body": json.dumps({"message": "CORS OK"})
        }

    try:
      
        raw_headers = event.get("headers", {}) or {}
        headers_normalized = {
            k.lower().replace("-", "_"): v
            for k, v in raw_headers.items()
        }

        user_id = headers_normalized.get("user_id")

        if not user_id:
            return {
                "statusCode": 400,
                "headers": cors,
                "body": json.dumps({"error": "user_id header is required"})
            }

        
        try:
            body = json.loads(event.get("body", "{}"))
        except:
            return {
                "statusCode": 400,
                "headers": cors,
                "body": json.dumps({"error": "Invalid JSON body"})
            }

      
        Title = body.get("Title")
        submission_date = body.get("submission_date")
        deadline = body.get("deadline")         
        description = body.get("description", "")
        status = body.get("status", "pending")
        class_id = body.get("class_id", "")

        # Required fields
        if not Title or not submission_date or not deadline:
            return {
                "statusCode": 400,
                "headers": cors,
                "body": json.dumps({
                    "error": "Missing required fields: Title, submission_date, deadline"
                })
            }

       
        try:
            datetime.strptime(submission_date, "%Y-%m-%d")
        except:
            return {
                "statusCode": 400,
                "headers": cors,
                "body": json.dumps({"error": "Invalid submission_date format"})
            }

        try:
            datetime.fromisoformat(deadline)
        except:
            return {
                "statusCode": 400,
                "headers": cors,
                "body": json.dumps({"error": "Invalid deadline ISO timestamp"})
            }

      
        task_id = str(uuid.uuid4())

       
        item = {
            "task_id": task_id,
            "user_id": user_id,
            "Title": Title,
            "description": description,
            "submission_date": submission_date,
            "deadline": deadline,
            "class_id": class_id,
            "status": status
        }

        table.put_item(Item=item)

        return {
            "statusCode": 200,
            "headers": cors,
            "body": json.dumps({
                "message": "Submission created successfully.",
                "task_id": task_id,
                "data": item
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": cors,
            "body": json.dumps({"error": str(e)})
        }
