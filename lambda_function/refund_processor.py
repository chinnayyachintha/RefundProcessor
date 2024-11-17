import boto3
import uuid
from decimal import Decimal
from datetime import datetime
from boto3.dynamodb.conditions import Key
import os
import requests # pip install requests

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')

# Retrieve environment variables
ledger_table_name = os.environ['LEDGER_TABLE']
audit_table_name = os.environ['AUDIT_TABLE']
payroc_api_token = os.environ['PAYROC_API_TOKEN']
processor_api_url = os.environ['PROCESSOR_API_URL']  # Retrieve Processor API URL dynamically

# Reference tables
ledger_table = dynamodb.Table(ledger_table_name)
audit_table = dynamodb.Table(audit_table_name)

# 1. Retrieve Ledger Entry for Refund Initiation
def retrieve_transaction(transaction_id):
    print(f"Retrieving ledger entry for Transaction ID: {transaction_id}")
    response = ledger_table.get_item(Key={'TransactionID': transaction_id})
    if 'Item' not in response:
        raise Exception("Transaction not found.")
    print("Ledger entry retrieved successfully.")
    create_audit_entry(transaction_id, None, "QUERY_LEDGER", None, response)
    return response['Item']

# 2. Validate Refund Eligibility
def validate_refund_eligibility(transaction):
    print(f"Validating refund eligibility for Transaction ID: {transaction['TransactionID']}")
    if transaction['Status'] != 'Success':
        raise Exception("Transaction not eligible for refund.")
    if 'Refunded' in transaction:
        raise Exception("Transaction already refunded.")
    print("Transaction is eligible for refund.")

# 3. Duplicate Refund Prevention
def check_duplicate_refund(transaction_id):
    print(f"Checking for duplicate refund for Transaction ID: {transaction_id}")
    response = ledger_table.query(
        IndexName='OriginalTransactionID-index',
        KeyConditionExpression=Key('OriginalTransactionID').eq(transaction_id)
    )
    if response['Count'] > 0:
        raise Exception("Duplicate refund detected.")
    print("No duplicate refunds detected.")

# 4. Adjust Charges (Fees and Taxes)
def adjust_charges(original_transaction, refund_amount):
    total_charges = original_transaction.get('Fees', 0) + original_transaction.get('Taxes', 0)
    adjusted_refund_amount = refund_amount - total_charges
    print(f"Adjusted refund amount: {adjusted_refund_amount}")
    return adjusted_refund_amount

# 5. Seek Refund from Payment Processor
def seek_refund_from_processor(transaction_id, refund_amount):
    headers = {
        "Authorization": f"Bearer {payroc_api_token}",
        "Content-Type": "application/json"
    }
    payload = {
        "transaction_id": transaction_id,
        "refund_amount": float(refund_amount)
    }
    try:
        print(f"Seeking refund from processor for Transaction ID: {transaction_id}")
        response = requests.post(processor_api_url, json=payload, headers=headers)
        response.raise_for_status()
        processor_response = response.json()

        if processor_response.get("status") != "success":
            raise Exception(f"Refund failed: {processor_response.get('message', 'Unknown error')}")
        print("Refund processed successfully by processor.")
        return processor_response

    except requests.exceptions.RequestException as e:
        raise Exception(f"Failed to connect to payment processor: {str(e)}")

# 6. Create Refund Entry in Ledger
def create_refund_entry(original_transaction, refund_amount, refund_reason, user_id):
    refund_transaction_id = f"{original_transaction['TransactionID']}-REFUND"
    refund_entry = {
        'TransactionID': refund_transaction_id,
        'OriginalTransactionID': original_transaction['TransactionID'],
        'Amount': -Decimal(refund_amount),
        'ProcessorID': original_transaction['ProcessorID'],
        'Status': 'Refunded',
        'Timestamp': datetime.utcnow().isoformat(),
        'RefundReason': refund_reason,
        'InitiatedBy': user_id
    }
    print(f"Creating refund ledger entry for Refund Transaction ID: {refund_transaction_id}")
    ledger_table.put_item(Item=refund_entry)
    create_audit_entry(refund_transaction_id, refund_amount, "CREATE_LEDGER", user_id, refund_entry)
    print("Refund ledger entry created successfully.")
    return refund_transaction_id

# 7. Persist Payment Audit Trail
def create_audit_entry(transaction_id, refund_amount, action, user_id, response):
    audit_entry = {
        'AuditID': str(uuid.uuid4()),
        'TransactionID': transaction_id,
        'Action': action,
        'Actor': user_id,
        'Timestamp': datetime.utcnow().isoformat(),
        'RefundAmount': refund_amount,
        'Response': response
    }
    print(f"Creating audit trail for Transaction ID: {transaction_id}, Action: {action}")
    audit_table.put_item(Item=audit_entry)
    print("Audit trail entry created successfully.")

# Main Refund Processing Logic
def process_refund(event, context):
    try:
        # Parse event details
        transaction_id = event['transaction_id']
        refund_amount = Decimal(event['refund_amount'])
        refund_reason = event['refund_reason']
        user_id = event['user_id']

        # Sequence 1: Retrieve ledger entry
        original_transaction = retrieve_transaction(transaction_id)

        # Sequence 2: Validate refund eligibility
        validate_refund_eligibility(original_transaction)

        # Sequence 3: Check for duplicate refunds
        check_duplicate_refund(transaction_id)

        # Sequence 4: Adjust refund amount
        adjusted_refund_amount = adjust_charges(original_transaction, refund_amount)

        # Sequence 5: Seek refund from payment processor
        processor_response = seek_refund_from_processor(transaction_id, adjusted_refund_amount)

        # Sequence 6: Create refund ledger entry
        refund_transaction_id = create_refund_entry(
            original_transaction, adjusted_refund_amount, refund_reason, user_id
        )

        # Sequence 7: Audit trail success
        create_audit_entry(refund_transaction_id, adjusted_refund_amount, "CREATE_REFUND", user_id, processor_response)

        # Sequence 8: Normalize processor response and send success to API
        success_response = {
            'message': 'Refund processed successfully.',
            'refund_transaction_id': refund_transaction_id,
            'status': 'success',
            'processor_message': processor_response.get('message', 'Refund approved by processor.')
        }

        # Final success response to API
        print("Final success response:", success_response)
        return {
            'statusCode': 200,
            'body': success_response
        }

    except Exception as e:
        # Handle errors gracefully
        error_response = {
            'message': str(e),
            'status': 'error'
        }
        print("Error response:", error_response)
        return {
            'statusCode': 400,
            'body': error_response
        }
