output "refund_log_group_name" {
  description = "The name of the CloudWatch Log Group used for the refund workflow."
  value       = aws_cloudwatch_log_group.refund_workflow_logs.name
}

output "refund_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group used for the refund workflow."
  value       = aws_cloudwatch_log_group.refund_workflow_logs.arn
}

output "refund_alarm_name" {
  description = "The name of the CloudWatch alarm monitoring refund workflow errors."
  value       = aws_cloudwatch_metric_alarm.refund_workflow_errors_alarm.alarm_name
}

output "refund_alarm_arn" {
  description = "The ARN of the CloudWatch alarm monitoring refund workflow errors."
  value       = aws_cloudwatch_metric_alarm.refund_workflow_errors_alarm.arn
}

output "refund_sns_topic_arn" {
  description = "The ARN of the SNS topic used for refund workflow notifications."
  value       = aws_sns_topic.refund_alerts.arn
}

output "refund_sns_email_subscription" {
  description = "The email address subscribed to the refund workflow SNS topic."
  value       = aws_sns_topic_subscription.refund_email_subscription.endpoint
}

output "refund_dashboard_name" {
  description = "The name of the CloudWatch dashboard used for monitoring the refund workflow."
  value       = aws_cloudwatch_dashboard.refund_workflow_dashboard.dashboard_name
}

output "refund_dashboard_url" {
  description = "The URL for accessing the CloudWatch dashboard for the refund workflow."
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.refund_workflow_dashboard.dashboard_name}"
}

output "refund_lambda_function_arn" {
  description = "The ARN of the Lambda function handling refund processing."
  value       = aws_lambda_function.refund_processing_lambda.arn
}

output "refund_lambda_function_name" {
  description = "The name of the Lambda function handling refund processing."
  value       = aws_lambda_function.refund_processing_lambda.function_name
}

output "refund_dynamodb_ledger_table_name" {
  description = "The name of the DynamoDB table storing refund ledger entries."
  value       = aws_dynamodb_table.PaymentLedger.name
}

output "refund_dynamodb_audit_table_name" {
  description = "The name of the DynamoDB table storing refund audit trail entries."
  value       = aws_dynamodb_table.PaymentAuditTrail.name
}

output "refund_dynamodb_ledger_table_arn" {
  description = "The ARN of the DynamoDB table storing refund ledger entries."
  value       = aws_dynamodb_table.PaymentLedger.arn
}

output "refund_dynamodb_audit_table_arn" {
  description = "The ARN of the DynamoDB table storing refund audit trail entries."
  value       = aws_dynamodb_table.PaymentAuditTrail.arn
}
