# Lambda acts as a relay between API Gateway and SageMaker

import json
import boto3

import os 

# Create SageMaker runtime client
runtime = boto3.client("sagemaker-runtime")

# Endpoint name passed from Terraform
ENDPOINT_NAME = os.environ["ENDPOINT_NAME"]

def lambda_handler(event, context):
    """
    Receives HTTP request from API Gateway
    Forwards payload to SageMaker endpoint
    Returns inference result
    """
    path = event.get("path")
    method = event.get("httpMethod")

    # ----------------------------------
    # HEALTH CHECK
    # ----------------------------------
    if path == "/ping" and method == "GET":
        return {
            "statusCode": 200,
            "body": json.dumps({"status": "ok"})
        }

    # ----------------------------------
    # INFERENCE (/predict)
    # ----------------------------------
    try:
        body = json.loads(event.get("body", "{}"))

        response = runtime.invoke_endpoint(
            EndpointName=ENDPOINT_NAME,
            ContentType="application/json",
            Body=json.dumps(body)
        )

        return {
            "statusCode": 200,
            "body": response["Body"].read().decode()
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }