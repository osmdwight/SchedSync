import json
import boto3

def lambda_handler(event, context):
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "GET, OPTIONS"
    }

    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }

    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('CLASSES')

        # Scan table to get all classes
        response = table.scan()
        items = response['Items']
        
        # Handle pagination if there are more items
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response['Items'])
        

        unique_by_composite = list({
            (
                item.get('class_code'), 
                tuple(item.get('days_of_week', [])), 
                item.get('location'), 
                item.get('professor'), 
                item.get('time_end'),
                item.get('time_start')
            ): {k: v for k, v in item.items() if k != 'user_id'}
            for item in items
        }.values())


        # Return the data as direct array 
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(unique_by_composite)
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': 'Failed to retrieve schedules',
                'details': str(e)
            })
        }
