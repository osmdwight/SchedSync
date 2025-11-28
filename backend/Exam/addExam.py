import json
import boto3
import uuid

dynamodb = boto3.resource('dynamodb')
exams_table = dynamodb.Table('Exams')

def lambda_handler(event, context):
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,user-id,user_id",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST",
        "Content-Type": "application/json"
    }

    # Handle OPTIONS pre-flight request
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }

    try:
        body = json.loads(event['body'])

        # Normalize headers
        raw_headers = event.get("headers", {})
        normalized = {k.lower(): v for k, v in raw_headers.items()}

        user_id = (
            normalized.get("user-id") or
            normalized.get("user_id")
        )

        if not user_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'user_id header is required'})
            }

        required_fields = ["exam_title", "description", "exam_date", "deadline","class_id"]
        missing = [f for f in required_fields if f not in body]

        if missing:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': f'Missing required fields: {missing}'})
            }

        exam_item = {
            'exam_id': str(uuid.uuid4()),
            'user_id': user_id,
            'exam_title': body['exam_title'],
            'description': body['description'],
            'exam_date': body['exam_date'],
            'deadline': body['deadline'],
            'class_id': body['class_id'],
            'status': "pending"
        }

        exams_table.put_item(Item=exam_item)

        return {
            'statusCode': 201,
            'headers': headers,
            'body': json.dumps({
                'message': 'Exam added successfully',
                'exam_id': exam_item['exam_id']
            })
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }
