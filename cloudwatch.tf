# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "refund_workflow_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 30 # Logs retention period
}

# CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "refund_workflow_log_stream" {
  name           = "${var.function_name}-stream"
  log_group_name = aws_cloudwatch_log_group.refund_workflow_logs.name
}

# CloudWatch Alarm for Refund Workflow Errors
resource "aws_cloudwatch_metric_alarm" "refund_workflow_errors_alarm" {
  alarm_name          = "${var.function_name}-ErrorsAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60 # Check every 1 minute
  statistic           = "Sum"
  threshold           = 1 # Alarm triggers if at least one error occurs
  alarm_description   = "Triggers when there are errors in the Refund Workflow Lambda"
  dimensions = {
    FunctionName = var.function_name
  }
  actions_enabled           = true
  alarm_actions             = [aws_sns_topic.alerts.arn]
  ok_actions                = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alerts" {
  name = "${var.function_name}-alerts"
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email_subscription" {
  for_each = toset(var.email_endpoints)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# CloudWatch Dashboard for Refund Workflow
resource "aws_cloudwatch_dashboard" "refund_dashboard" {
  dashboard_name = "${var.function_name}-Dashboard"
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
            ["AWS/Lambda", "Duration", "FunctionName", var.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", var.function_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Refund Workflow Lambda Metrics"
          period  = 60
        }
      }
    ]
  })
}
