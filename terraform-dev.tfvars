# AWS Region where resources will be deployed
aws_region = "ca-central-1"

# Name of the Lambda function
function_name = "RefundProcessor"

# API Token for the payment processor
payroc_api_token = "YOUR_PAYROC_API_TOKEN"

# URL of the payment processor API
processor_api_url = "https://api.payroc.com/v1"

# Name of the S3 bucket for the Lambda deployment package
s3_bucket_name = "refund-processor-bucket"
# Email addresses to receive CloudWatch alarms
email_endpoints = [
"chinnayya.chintha339@gmail.com"]