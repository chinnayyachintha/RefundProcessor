# AWS Region where resources will be deployed
variable "aws_region" {
  type        = string
  description = "AWS Region to deploy resources"
}

# Name of the Lambda function
variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

# Email addresses to receive CloudWatch alarms
variable "email_endpoints" {
  type        = list(string)
  description = "Email addresses to receive CloudWatch alarms"
}