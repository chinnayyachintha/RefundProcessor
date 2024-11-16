# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "refund_workflow_logs" {
  name              = "/aws/lambda/refund-workflow"
  retention_in_days = 30 # Logs retention period
}

# Create CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "refund_workflow_log_stream" {
  name           = "${var.function_name}-stream"
  log_group_name = aws_cloudwatch_log_group.refund_workflow_logs.name
}

# CloudWatch Alarm for Refund Workflow Errors
resource "aws_cloudwatch_metric_alarm" "refund_workflow_errors_alarm" {
  alarm_name          = "${var.function_name}-WorkflowErrors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers when there are errors in the Refund Workflow Lambda"
  dimensions = {
    FunctionName = "refund-workflow-lambda" # Replace with your Lambda function name
  }
  actions_enabled           = true
  alarm_actions             = [aws_sns_topic.alerts.arn]
  ok_actions                = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alerts" {
  name = "${var.function_name}-workflow-alerts"
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email_subscription" {
  for_each = toset(var.email_endpoints)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value # Replace with your emails
}

# CloudWatch Dashboard for Refund Workflow
resource "aws_cloudwatch_dashboard" "refund_dashboard" {
  dashboard_name = "${var.function_name}-WorkflowDashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "refund-workflow-lambda"],
            [".", "Errors", ".", "."],
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Refund Workflow Lambda Metrics"
          period  = 60
        }
      }
    ]
  })
}
