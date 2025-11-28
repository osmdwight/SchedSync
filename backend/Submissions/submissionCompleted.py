import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Submissions")

def lambda_handler(event, context):
    headers = {
        "Access-Control-Allow-Headers": "Content-Type,user_id",  
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS,PUT,POST,GET,DELETE",
    }

    try:
        # Get user_id from headers
        user_id = event.get('headers', {}).get('user_id')
        if not user_id:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "user_id header is required"})
            }

        # Parse body
        body = json.loads(event.get("body", "{}"))
        task_id = body.get("task_id")
        
        if not task_id:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "task_id is required"})
            }

        try:
            response = table.get_item(Key={
                "task_id": task_id,
                "user_id": user_id
            })
            
            if 'Item' not in response:
                return {
                    "statusCode": 404,
                    "headers": headers,
                    "body": json.dumps({"error": "Submission not found for this user"})
                }
                
        except ClientError as e:
            return {
                "statusCode": 500,
                "headers": headers,
                "body": json.dumps({"error": f"Error checking submission: {str(e)}"})
            }

        # Mark as completed
        response = table.update_item(
            Key={
                "task_id": task_id,
                "user_id": user_id
            },
            UpdateExpression="SET #status = :status",
            ExpressionAttributeNames={
                "#status": "status"
            },
            ExpressionAttributeValues={
                ":status": "completed"
            },
            ReturnValues="ALL_NEW"
        )

        updated_item = response.get('Attributes', {})

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "message": "Submission marked as completed!",
                "updated_submission": updated_item
            })
        }

    except ClientError as e:
        error_msg = str(e)
        if "ValidationException" in error_msg:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "Invalid task_id format"})
            }
        elif "ConditionalCheckFailedException" in error_msg:
            return {
                "statusCode": 404,
                "headers": headers,
                "body": json.dumps({"error": "Submission not found"})
            }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": str(e)})
        }
