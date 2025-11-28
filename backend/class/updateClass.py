import json
import boto3
from boto3.dynamodb.conditions import Attr
from botocore.exceptions import ClientError
from datetime import datetime

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
        # Extract user_id from headers
        user_id = event.get("headers", {}).get("user_id")
        if not user_id:
            return build_response(400, {
                "status": "error",
                "message": "user_id header is required"
            })

        # Parse body
        body = event.get("body")
        if not body:
            return build_response(400, {
                "status": "error",
                "message": "Request body is missing."
            })

        data = json.loads(body) if isinstance(body, str) else body

        # Required: class_code
        class_code = data.get("class_code")
        if not class_code:
            return build_response(400, {
                "status": "error",
                "message": "class_code is required in request body."
            })

        # Fetch existing class
        try:
            response = table.get_item(
                Key={
                    "class_code": class_code,
                    "user_id": user_id
                }
            )
            existing_class = response.get("Item")
            if not existing_class:
                return build_response(404, {
                    "status": "error",
                    "message": "Class not found for this user."
                })

        except ClientError as e:
            return build_response(500, {
                "status": "error",
                "message": f"Error fetching class: {str(e)}"
            })

        # Determine updated values (or default to existing)
        time_start = data.get("time_start", existing_class.get("time_start"))
        time_end = data.get("time_end", existing_class.get("time_end"))
        days_of_week = data.get("days_of_week", existing_class.get("days_of_week"))

        # Check conflict only if schedule fields changed
        if "time_start" in data or "time_end" in data or "days_of_week" in data:
            try:
                conflict = check_schedule_conflict(
                    table,
                    user_id,
                    days_of_week,
                    time_start,
                    time_end,
                    class_code
                )
                if conflict:
                    return build_response(400, {
                        "status": "error",
                        "message": "Schedule conflict with existing class",
                        "conflict_with": conflict
                    })
            except Exception as e:
                return build_response(500, {
                    "status": "error",
                    "message": f"Error checking schedule: {str(e)}"
                })

        updatable_fields = [
            "class_name",
            "time_start",
            "time_end",
            "professor",
            "location",
            "days_of_week",
        ]

        set_parts = []
        expr_attr_values = {}
        expr_attr_names = {}

        for field in updatable_fields:
            if field in data:
                name_placeholder = f"#{field}"
                value_placeholder = f":{field}"
                set_parts.append(f"{name_placeholder} = {value_placeholder}")
                expr_attr_values[value_placeholder] = data[field]
                expr_attr_names[name_placeholder] = field

        if not set_parts:
            return build_response(400, {
                "status": "error",
                "message": "No updatable fields provided."
            })

        update_expression = "SET " + ", ".join(set_parts)

        # Perform update
        resp = table.update_item(
            Key={
                "class_code": class_code,
                "user_id": user_id
            },
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expr_attr_values,
            ExpressionAttributeNames=expr_attr_names,
            ReturnValues="ALL_NEW"
        )

        updated = resp.get("Attributes", {})

        return build_response(200, {
            "status": "success",
            "data": updated
        })

    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })




def parse_time(tstr: str):
    tstr = tstr.strip()
    time_formats = ["%H:%M:%S", "%H:%M", "%I:%M %p", "%I:%M:%S %p"]

    for fmt in time_formats:
        try:
            dt = datetime.strptime(tstr, fmt)
            return dt.time()
        except ValueError:
            continue

    raise ValueError(f"Unable to parse time: {tstr}")


def is_time_overlapping(start1, end1, start2, end2):
    return not (end1 <= start2 or end2 <= start1)


def check_schedule_conflict(table, user_id, new_days, new_start_str, new_end_str, exclude_class_code=None):
    try:
        new_start = parse_time(new_start_str)
        new_end = parse_time(new_end_str)
    except ValueError as e:
        raise Exception(f"Invalid time format: {str(e)}")

    if new_start >= new_end:
        raise Exception("time_start must be earlier than time_end")

    try:
        response = table.scan(
            FilterExpression=Attr("user_id").eq(user_id)
        )
        existing_classes = response.get("Items", [])
    except ClientError as e:
        raise Exception(f"Database query error: {str(e)}")

    for cls in existing_classes:

        if cls.get("class_code") == exclude_class_code:
            continue

        cls_days = cls.get("days_of_week", [])
        cls_start_str = cls.get("time_start")
        cls_end_str = cls.get("time_end")

        shared_days = [day for day in new_days if day in cls_days]
        if not shared_days:
            continue

        try:
            cls_start = parse_time(cls_start_str)
            cls_end = parse_time(cls_end_str)
        except ValueError:
            continue

        if is_time_overlapping(new_start, new_end, cls_start, cls_end):
            return {
                "class_name": cls.get("class_name"),
                "class_code": cls.get("class_code"),
                "time_start": cls_start_str,
                "time_end": cls_end_str,
                "days_of_week": cls_days,
                "professor": cls.get("professor"),
                "location": cls.get("location"),
                "conflicting_days": shared_days
            }

    return None
