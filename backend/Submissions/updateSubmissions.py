import json
import boto3
from botocore.exceptions import ClientError
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Submissions")

def lambda_handler(event, context):
    headers = {
        "Access-Control-Allow-Headers": "Content-Type,user_id,user-id",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS,PUT,POST,GET,DELETE",
    }

    try:
        # ---- USER ID CHECK ----
        user_id = event.get("headers", {}).get("user_id") or event.get("headers", {}).get("user-id")
        if not user_id:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "user_id header is required"})
            }

        # ---- BODY / TASK ID ----
        body = json.loads(event.get("body", "{}"))
        task_id = body.get("task_id")

        if not task_id:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "task_id is required"})
            }

        # ---- CHECK IF SUBMISSION EXISTS ----
        response = table.get_item(Key={"task_id": task_id, "user_id": user_id})
        if "Item" not in response:
            return {
                "statusCode": 404,
                "headers": headers,
                "body": json.dumps({"error": "Submission not found for this user"})
            }

        # ---- PREPARE UPDATE ----
        update_expression = "SET "
        expression_attribute_values = {}
        expression_attribute_names = {}

        updatable_fields = ["Title", "description", "submission_date", "deadline", "status", "class_id"]

        # ---- VALIDATION ----
        if "submission_date" in body:
            try:
                datetime.strptime(body["submission_date"], "%Y-%m-%d")
            except ValueError:
                return {
                    "statusCode": 400,
                    "headers": headers,
                    "body": json.dumps({"error": "submission_date must be YYYY-MM-DD"})
                }

        if "deadline" in body:
            try:
                dt = body["deadline"]

                if "T" in dt:
                    # Full ISO datetime: YYYY-MM-DDTHH:MM:SS
                    datetime.strptime(dt, "%Y-%m-%dT%H:%M:%S")
                else:
                    # TIME ONLY
                    parts = dt.split(":")
                    if len(parts) == 2:
                        datetime.strptime(dt, "%H:%M")
                    elif len(parts) == 3:
                        datetime.strptime(dt, "%H:%M:%S")
                    else:
                        raise ValueError()

            except ValueError:
                return {
                    "statusCode": 400,
                    "headers": headers,
                    "body": json.dumps({
                        "error": "deadline must be YYYY-MM-DDTHH:MM:SS or HH:MM or HH:MM:SS"
                    })
                }

        # ---- BUILD UPDATE EXPRESSION ----
        set_parts = []
        for field in updatable_fields:
            if field in body:
                value_placeholder = f":{field}"
                set_parts.append(f"#{field} = {value_placeholder}")
                expression_attribute_values[value_placeholder] = body[field]
                expression_attribute_names[f"#{field}"] = field

        if not set_parts:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "No updatable fields provided"})
            }

        update_expression += ", ".join(set_parts)

        # ---- UPDATE DYNAMODB ----
        response = table.update_item(
            Key={"task_id": task_id, "user_id": user_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ExpressionAttributeNames=expression_attribute_names,
            ReturnValues="ALL_NEW"
        )

        updated_item = response.get("Attributes", {})

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "message": "Submission updated successfully!",
                "updated_submission": updated_item
            })
        }

    except ClientError as e:
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
