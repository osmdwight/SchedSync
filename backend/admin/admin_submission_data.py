import boto3
import json

def build_response(status_code, body_dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,GET",
            "Access-Control-Allow-Headers": "Content-Type,user_id"
        },
        "body": json.dumps(body_dict)
    }

dynamodb = boto3.resource("dynamodb")

def lambda_handler(event, context):
    try:
        users_table = dynamodb.Table("users")
        submissions_table = dynamodb.Table("Submissions")
        
        users_response = users_table.scan(
            ProjectionExpression='user_id, first_name, last_name'
        )
        users = users_response.get('Items', [])
        
        submissions_response = submissions_table.scan(
            ProjectionExpression='user_id, Title, submission_date, task_id, deadline, #stat',
            ExpressionAttributeNames={
                '#stat': 'status'
            }
        )
        all_submissions = submissions_response.get('Items', [])
        
        formatted_submissions = []
        
        for user in users:
            user_id = user.get('user_id')
            if user_id:
                name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
                
                user_submissions = [submission for submission in all_submissions if submission.get('user_id') == user_id]
                
                for submission in user_submissions:
                    formatted_submissions.append({

                        "task_id": submission.get('task_id',''),
                        "Title": submission.get('Title',''),
                        "deadline": submission.get('deadline',''),
                        "status": submission.get('status', ''),
                        "user_id": user_id,
                        "user_name": name
                    })
                    
        
        return build_response(200, {
            "status": "success",
            "data": formatted_submissions,
            "message": f"Retrieved {len(formatted_submissions)} records"
        })
    
    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })
