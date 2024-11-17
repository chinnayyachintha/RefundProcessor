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

# API Token for the payment processor
variable "payroc_api_token" {
  type        = string
  description = "API Token for the payment processor"
}

# URL of the payment processor
variable "processor_api_url" {
  type        = string
  description = "URL of the payment processor"
}

# Email addresses to receive CloudWatch alarms
variable "email_endpoints" {
  type        = list(string)
  description = "Email addresses to receive CloudWatch alarms"
}