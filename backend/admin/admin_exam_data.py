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
        exams_table = dynamodb.Table("Exams")
        
        users_response = users_table.scan(
            ProjectionExpression='user_id, first_name, last_name'
        )
        users = users_response.get('Items', [])
        
        exams_response = exams_table.scan(
            ProjectionExpression='user_id, exam_date, exam_title, exam_id, deadline, #stat',
            ExpressionAttributeNames={
                '#stat': 'status'
            }
        )
        all_exams = exams_response.get('Items', [])
        
        formatted_exams = []
        
        for user in users:
            user_id = user.get('user_id')
            if user_id:
                name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
                
                user_exams = [exam for exam in all_exams if exam.get('user_id') == user_id]
                
                for exam in user_exams:
                    formatted_exams.append({
                        "name": name,
                        "exam_title": exam.get('exam_title', ''),
                        "exam_date": exam.get('exam_date', ''),
                        "status": exam.get('status', ''),
                        "user_id": user_id,
                        "exam_id": exam.get('exam_id', ''),
                        "deadline": exam.get('deadline','')
                    })
        
        return build_response(200, {
            "status": "success",
            "data": formatted_exams,
            "message": f"Retrieved {len(formatted_exams)} formatted exam records"
        })
    
    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })
