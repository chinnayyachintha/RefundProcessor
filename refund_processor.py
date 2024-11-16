import boto3
import uuid
from decimal import Decimal
from datetime import datetime
from boto3.dynamodb.conditions import Key
import os

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')

# Retrieve environment variables for table names
ledger_table_name = os.environ['LEDGER_TABLE']
audit_table_name = os.environ['AUDIT_TABLE']

# Reference tables using environment variables
ledger_table = dynamodb.Table(ledger_table_name)
audit_table = dynamodb.Table(audit_table_name)

# Retrieve Ledger Entries
def retrieve_transaction(transaction_id):
    # Querying the PaymentLedger table
    response = ledger_table.get_item(Key={'TransactionID': transaction_id})
    if 'Item' not in response:
        raise Exception("Transaction not found.")
    return response['Item']

# Revert Ledger Entries (Refund)
def create_refund_entry(original_transaction, refund_amount, refund_reason, user_id):
    refund_transaction_id = f"{original_transaction['TransactionID']}-REFUND"
    
    refund_entry = {
        'TransactionID': refund_transaction_id,
        'OriginalTransactionID': original_transaction['TransactionID'],
        'Amount': -Decimal(refund_amount),  # Refund as a negative value
        'ProcessorID': original_transaction['ProcessorID'],
        'Status': 'Refunded',
        'Timestamp': datetime.utcnow().isoformat(),
        'RefundReason': refund_reason,
        'InitiatedBy': user_id
    }
    
    # Add refund entry to PaymentLedger
    ledger_table.put_item(Item=refund_entry)
    return refund_transaction_id

# Validate Refund Eligibility
def validate_refund_eligibility(transaction):
    if transaction['Status'] != 'Success':
        raise Exception("Transaction not eligible for refund.")
    if 'Refunded' in transaction:
        raise Exception("Transaction already refunded.")

# Persist Payment Audit Trail
def create_audit_entry(transaction_id, refund_amount, action, user_id, response):
    audit_entry = {
        'AuditID': str(uuid.uuid4()),  # Unique ID for audit log entry
        'TransactionID': transaction_id,
        'Action': action,
        'Actor': user_id,
        'Timestamp': datetime.utcnow().isoformat(),
        'RefundAmount': refund_amount,
        'Response': response
    }
    audit_table.put_item(Item=audit_entry)

# Adjust Charges (fees and taxes)
def adjust_charges(original_transaction, refund_amount):
    total_charges = original_transaction.get('Fees', 0) + original_transaction.get('Taxes', 0)
    adjusted_refund_amount = refund_amount - total_charges
    return adjusted_refund_amount

# Calculate Remaining Refund Amount (for partial refunds)
def calculate_remaining_refund(original_transaction, total_refunded):
    max_refundable = original_transaction['Amount']
    return max(0, max_refundable - total_refunded)

# Duplicate Refund Prevention (check if refund has already been processed)
def check_duplicate_refund(transaction_id):
    response = ledger_table.query(
        IndexName='OriginalTransactionID-index',  # Assuming you have an index for OriginalTransactionID
        KeyConditionExpression=Key('OriginalTransactionID').eq(transaction_id)
    )
    if response['Count'] > 0:
        raise Exception("Duplicate refund detected.")

# Main refund processing logic
def process_refund(event, context):
    try:
        # Parse the event for the required information (could be from API Gateway)
        transaction_id = event['transaction_id']
        refund_amount = event['refund_amount']
        refund_reason = event['refund_reason']
        user_id = event['user_id']

        # Retrieve the original transaction from PaymentLedger
        original_transaction = retrieve_transaction(transaction_id)
        
        # Validate if the transaction is eligible for a refund
        validate_refund_eligibility(original_transaction)

        # Check for duplicate refund
        check_duplicate_refund(transaction_id)

        # Adjust refund amount based on fees and taxes (optional)
        adjusted_refund_amount = adjust_charges(original_transaction, refund_amount)
        
        # Ensure we are not refunding more than the allowable amount
        remaining_refund = calculate_remaining_refund(original_transaction, adjusted_refund_amount)

        # Create refund entry in the PaymentLedger
        refund_transaction_id = create_refund_entry(
            original_transaction, remaining_refund, refund_reason, user_id
        )
        
        # Log the refund action in the audit trail
        create_audit_entry(
            transaction_id=refund_transaction_id,
            refund_amount=remaining_refund,
            action="REFUND",
            user_id=user_id,
            response="Refund successfully processed."
        )

        # Return the response for the Lambda function
        return {
            'statusCode': 200,
            'body': {
                'message': 'Refund processed successfully.',
                'refund_transaction_id': refund_transaction_id
            }
        }

    except Exception as e:
        # Handle errors gracefully and log
        return {
            'statusCode': 400,
            'body': {
                'message': str(e)
            }
        }