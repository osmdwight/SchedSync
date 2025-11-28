import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Submissions")

def lambda_handler(event, context):
    headers = {
        "Access-Control-Allow-Headers": "Content-Type,user_id",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST,DELETE",
    }

    try:
        user_id = None
        if event.get('headers'):
            user_id = event['headers'].get('user_id')
        
        if not user_id:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "user_id header is required"})
            }

        task_id = None        
        if event.get('queryStringParameters'):
            task_id = event['queryStringParameters'].get('task_id')
        
        if not task_id and event.get('body'):
            try:
                body = json.loads(event['body'])
                task_id = body.get('task_id')
            except:
                pass

        if not task_id:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "task_id is required in query parameters or request body"})
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

        table.delete_item(Key={
            "task_id": task_id,      
            "user_id": user_id       
        })

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "message": "Submission deleted successfully",
                "deleted_submission": {
                    "user_id": user_id,
                    "task_id": task_id
                }
            })
        }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ConditionalCheckFailedException':
            return {
                "statusCode": 404,
                "headers": headers,
                "body": json.dumps({"error": "Submission not found"})
            }
        else:
            return {
                "statusCode": 500,
                "headers": headers,
                "body": json.dumps({"error": f"DynamoDB error: {str(e)}"})
            }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": str(e)})
        }
