import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Exams")

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,user-id,user_id,user-id",
    "Access-Control-Allow-Methods": "OPTIONS,PUT,GET,POST,DELETE"
}

def lambda_handler(event, context):
    try:
        # Normalize headers
        headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
        user_id = headers.get("user-id") or headers.get("user_id")

        if not user_id:
            return {"statusCode": 400, "headers": CORS,
                    "body": json.dumps({"error": "user_id header is required"})}

        if not event.get("body"):
            return {"statusCode": 400, "headers": CORS,
                    "body": json.dumps({"error": "Missing request body"})}

        body = json.loads(event["body"])

        # exam_id required
        exam_id = body.get("exam_id")
        if not exam_id:
            return {"statusCode": 400, "headers": CORS,
                    "body": json.dumps({"error": "exam_id is required"})}

        # Check exam exists
        item = table.get_item(Key={"exam_id": exam_id}).get("Item")
        if not item:
            return {"statusCode": 404, "headers": CORS,
                    "body": json.dumps({"error": "Exam not found"})}

        # Ensure exam belongs to user
        if item["user_id"] != user_id:
            return {"statusCode": 403, "headers": CORS,
                    "body": json.dumps({"error": "Unauthorized"})}

        # Allowed fields
        updatable_fields = [
            "exam_title",
            "class_id",
            "deadline",
            "exam_date",
            "description",
            "status"
        ]

        # Explicitly remove exam_datetime if client requests it
        if body.get("remove_exam_datetime") == True:
            table.update_item(
                Key={"exam_id": exam_id},
                UpdateExpression="REMOVE exam_datetime"
            )

        update_expression_parts = []
        expression_attribute_values = {}
        expression_attribute_names = {}

        if body.get("mark_as_complete") == True:
            body["status"] = "completed"

                # Build update expression
        for field in updatable_fields:
            if field in body:
                update_expression_parts.append(f"#{field} = :{field}")
                expression_attribute_names[f"#{field}"] = field
                expression_attribute_values[f":{field}"] = body[field]

        if not update_expression_parts:
                return {"statusCode": 400, "headers": CORS,
                        "body": json.dumps({"error": "No valid fields to update"})}

        update_expression = "SET " + ", ".join(update_expression_parts)

        result = table.update_item(
            Key={"exam_id": exam_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ExpressionAttributeNames=expression_attribute_names,
            ReturnValues="ALL_NEW"
        )

        return {
            "statusCode": 200,
            "headers": CORS,
            "body": json.dumps({
                "message": "Exam updated successfully",
                "updated_exam": result.get("Attributes")
            })                
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": CORS,
            "body": json.dumps({"error": str(e)})
        }
