import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET, OPTIONS'
    }

    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }

    try:
        # Scan table to get all items
        response = table.scan()
        items = response['Items']
        
        # Handle pagination
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response['Items'])
        
        if items:
            print("First item fields:", items[0].keys())
        
        user_data = []
        for item in items:
            user_data.append({
                'user_id': item.get('user_id'),
                'first_name': item.get('first_name'),
                'last_name': item.get('last_name'),
                'email': item.get('email')
            })
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(user_data)
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': 'Failed to retrieve users',
                'details': str(e)
            })
        }
