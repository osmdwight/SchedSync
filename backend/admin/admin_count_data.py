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
        submissions_table = dynamodb.Table("Submissions")
        
        users_count = users_table.scan(Select='COUNT')['Count']
        exams_count = exams_table.scan(Select='COUNT')['Count']
        submissions_count = submissions_table.scan(Select='COUNT')['Count']
        
        return build_response(200, {
            "status": "success",
            "data": {
                "total_users": users_count,
                "total_exams": exams_count,
                "total_submissions": submissions_count
            },
            "message": f"Database counts: {users_count} users, {exams_count} exams, {submissions_count} submissions"
        })
    
    except Exception as e:
        return build_response(500, {
            "status": "error",
            "message": str(e)
        })
