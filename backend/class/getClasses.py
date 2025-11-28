import json
import boto3
from boto3.dynamodb.conditions import Attr
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("CLASSES")

def build_response(status_code, body_dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,user_id",
            "Access-Control-Allow-Methods": "OPTIONS,GET"
        },
        "body": json.dumps(body_dict)
    }

def lambda_handler(event, context):
    # Handle OPTIONS pre-flight request
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,user_id',
                'Access-Control-Allow-Methods': 'OPTIONS,GET',
                'Content-Type': 'application/json'
            },
            'body': ''
        }
    
    try:
        # Extract user_id 
        user_id = None
        if event.get('headers'):
            user_id = event['headers'].get('user_id')
        
        # Validate user_id
        if not user_id:
            return build_response(400, {
                "status": "error",
                "message": "user_id header is required"
            })

        class_code = None
        if event.get('queryStringParameters'):
            class_code = event['queryStringParameters'].get('class_code')

        if class_code:
            # Get ONE specific class
            try:
                response = table.get_item(
                    Key={
                        "class_code": class_code,
                        "user_id": user_id
                    }
                )
                
                if 'Item' in response:
                    return build_response(200, {
                        "status": "success",
                        "data": response['Item']
                    })
                else:
                    return build_response(404, {
                        "status": "error",
                        "message": "Class not found for this user"
                    })
                    
            except ClientError as e:
                return build_response(500, {
                    "status": "error",
                    "message": f"Error fetching class: {str(e)}"
                })
        else:
            # Get ALL classes for this user
            resp = table.scan(
                FilterExpression=Attr("user_id").eq(user_id)
            )
            items = resp.get("Items", [])

            return build_response(200, {
                "status": "success",
                "data": items,
            })

    except ClientError as e:
        return build_response(500, {
            "status": "error",
            "message": e.response["Error"]["Message"]
        })
    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })
