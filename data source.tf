# Retrieves information about the IAM identity that is making the AWS calls
data "aws_caller_identity" "current" {}

# Fetch Existing Private Subnet by Tag
data "aws_subnet" "private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["PaymentGateway-pvt-subnet"] # Replace with the tag of your private subnet
  }
}

# Fetch Existing Security Group by Tag
data "aws_security_group" "private_sg" {
  filter {
    name   = "tag:Name"
    values = ["PaymentGateway-pvt-sg"] # Replace with the tag of your Lambda security group
  }
}

# Retrieves information about the DynamoDB table named "PaymentLedger"
data "aws_dynamodb_table" "payment_ledger" {
  name = "PaymentLedger"
}

# Retrieves information about the DynamoDB table named "PaymentAuditTrail"
data "aws_dynamodb_table" "payment_audit_trail" {
  name = "PaymentAuditTrail"
}