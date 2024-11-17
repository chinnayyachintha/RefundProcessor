resource "aws_lambda_function" "process_refund" {
  function_name    = var.function_name
  runtime          = "python3.9"                       # Adjust the runtime as needed
  handler          = "refund_processor.process_refund" # Adjust the handler as needed
  role             = aws_iam_role.refund_process_role.arn
  filename         = "refund_processor.zip" # Zip containing the Lambda code
  source_code_hash = filebase64sha256("refund_processor.zip")

  environment {
    variables = {
      LEDGER_TABLE     = data.aws_dynamodb_table.payment_ledger.name
      AUDIT_TABLE      = data.aws_dynamodb_table.payment_audit_trail.name
      PAYROC_API_TOKEN = var.payroc_api_token           # API Token for processor
      PROCESSOR_API_URL = var.processor_api_url         # The URL of the payment processor
    }
  }

  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnet.id]     # Reference the private subnet
    security_group_ids = [data.aws_security_group.private_sg.id] # Reference the security group
  }

}

# resource "aws_lambda_permission" "api_gateway_invoke" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.process_refund.function_name
#   principal     = "apigateway.amazonaws.com"
# }