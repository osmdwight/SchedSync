import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
exams_table = dynamodb.Table('Exams')

def lambda_handler(event, context):
    cors = {
        "Access-Control-Allow-Headers": "Content-Type,user-id,user_id",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST,DELETE"
    }

    try:
        # ------------------------------------------------------------
        # NORMALIZE HEADERS (supports BOTH user-id AND user_id)
        # ------------------------------------------------------------
        raw_headers = event.get("headers", {}) or {}
        normalized = {
            k.lower().replace('-', '_'): v
            for k, v in raw_headers.items()
        }

        user_id = normalized.get("user_id")

        if not user_id:
            return {
                "statusCode": 400,
                "headers": cors,
                "body": json.dumps({"error": "user_id header is required"})
            }

        # ------------------------------------------------------------
        # GET exam_id from query OR request body
        # ------------------------------------------------------------
        exam_id = None

        if event.get("queryStringParameters"):
            exam_id = event["queryStringParameters"].get("exam_id")

        if not exam_id and event.get("body"):
            try:
                body = json.loads(event["body"])
                exam_id = body.get("exam_id")
            except:
                pass

        if not exam_id:
            return {
                "statusCode": 400,
                "headers": cors,
                "body": json.dumps({"error": "exam_id is required"})
            }

        # ------------------------------------------------------------
        # DELETE ITEM (must include BOTH PK & SK)
        # ------------------------------------------------------------
        exams_table.delete_item(
            Key={
                #updatedd
                "exam_id": exam_id
            }
        )

        return {
            "statusCode": 200,
            "headers": cors,
            "body": json.dumps({
                "message": "Exam deleted successfully",
                "deleted_exam": {
                    "user_id": user_id,
                    "exam_id": exam_id
                }
            })
        }

    except ClientError as e:
        return {
            "statusCode": 500,
            "headers": cors,
            "body": json.dumps({"error": f"DynamoDB error: {str(e)}"})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": cors,
            "body": json.dumps({"error": str(e)})
        }
