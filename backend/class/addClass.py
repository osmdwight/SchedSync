import json
import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime

def build_response(status_code, body_dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT,DELETE",
            "Access-Control-Allow-Headers": "Content-Type,user_id"
        },
        "body": json.dumps(body_dict)
    }

    

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("CLASSES")

def lambda_handler(event, context):
    try:
        event_headers = {k.lower(): v.strip() if isinstance(v, str) else v 
                        for k, v in (event.get("headers") or {}).items()}
        
        user_id = event_headers.get("user_id")
        
        print(f"Received headers: {event_headers}")
        print(f"Extracted user_id: '{user_id}'")
        
        if not user_id:
            return build_response(400, {
                "status": "error", 
                "message": "user_id header is required"
            })

        body = event.get("body")
        if not body:
            return build_response(400, {
                "status": "error", 
                "message": "Request body is missing"
            })
            
        data = json.loads(body) if isinstance(body, str) else body

        # Extract fields
        class_code = data.get("classCode")
        class_name = data.get("className")
        time_start = data.get("timeStart")
        time_end = data.get("timeEnd")
        days_of_week = data.get("daysOfWeek")
        professor = data.get("professor", "")
        location = data.get("location", "")

        # Validation
        if not class_code:
            return build_response(400, {
                "status": "error",
                "message": "Class Code is required"
            })
        if not class_name:
            return build_response(400, {
                "status": "error", 
                "message": "Class Name is required"
            })
        if not days_of_week:
            return build_response(400, {
                "status": "error",
                "message": "Days of Week are required"
            })
        if not time_start or not time_end:
            return build_response(400, {
                "status": "error",
                "message": "Time Start and Time End are required"
            })

        # Check if class already exists
        existing_class = table.query(
            KeyConditionExpression=Key("user_id").eq(user_id) & Key("class_code").eq(class_code)
        )

        if existing_class["Items"]:
            return build_response(400, {
                "status": "error",
                "message": "Class with this code already exists"
            })

        # Check schedule conflict
        conflict = check_schedule_conflict(table, user_id, days_of_week, time_start, time_end, class_code)
        if conflict:
            return build_response(400, {
                "status": "error",
                "message": "Schedule conflict with existing class",
                "conflict_with": conflict
            })

        # Create class item
        class_item = {
            "user_id": user_id,
            "class_code": class_code,
            "class_name": class_name,
            "time_start": time_start,
            "time_end": time_end,
            "days_of_week": days_of_week,
            "professor": professor,
            "location": location
        }

        table.put_item(Item=class_item)

        return build_response(200, {
            "status": "success",
            "message": "Class created successfully",
            "class": {
                "class_code": class_code,
                "class_name": class_name
            }
        })

    except ClientError as e:
        return build_response(500, {
            "status": "error",
            "message": f"Database error: {str(e)}"
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
        raise Exception("timeStart must be earlier than timeEnd")

    response = table.scan(
        FilterExpression=Attr('user_id').eq(user_id)
    )
    existing_classes = response.get('Items', [])

    for cls in existing_classes:
        if cls.get('class_code') == exclude_class_code:
            continue

        cls_days = cls.get('days_of_week', [])
        cls_start_str = cls.get('time_start')
        cls_end_str = cls.get('time_end')

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
                "class_name": cls.get('class_name'),
                "class_code": cls.get('class_code'),
                "time_start": cls_start_str,
                "time_end": cls_end_str,
                "days_of_week": cls_days
            }

    return None
