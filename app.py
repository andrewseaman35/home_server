from flask import Flask, request, jsonify
import boto3
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Initialize AWS SNS client
sns = boto3.client(
    'sns',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
    region_name=os.getenv('AWS_REGION', 'us-east-1')
)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy'}), 200

@app.route('/notify', methods=['POST'])
def send_notification():
    try:
        data = request.get_json()

        if not data or 'message' not in data:
            return jsonify({'error': 'Missing required field: message'}), 400

        topic_arn = os.getenv('AWS_SNS_TOPIC_ARN')
        if not topic_arn:
            return jsonify({'error': 'AWS_SNS_TOPIC_ARN not configured'}), 500

        # Send message to SNS topic
        response = sns.publish(
            TopicArn=topic_arn,
            Message=data['message'],
            Subject=data.get('subject', 'Notification from aws_notify')
        )

        return jsonify({
            'message': 'Notification sent successfully',
            'message_id': response['MessageId']
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5889)