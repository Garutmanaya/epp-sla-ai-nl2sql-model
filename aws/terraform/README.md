# epp-sla-reporter-text2sql-model – Modular Terraform Deployment

## Overview

This project provides a **modular, production-grade Terraform setup** for deploying a serverless ML inference pipeline.

## Architecture

Client → API Gateway → Lambda → SageMaker Serverless → Docker (FastAPI + Models)

## Components

* Amazon SageMaker – serverless inference
* AWS Lambda – request relay
* Amazon API Gateway – public API
* IAM roles – fully managed by Terraform

## Features

* Modular architecture
* No manual setup required
* Fully reproducible
* Supports multi-model logic inside container

## Deploy

```bash
terraform init
terraform apply -var="ecr_image=<ECR_IMAGE_URI>"
```

## Output

```bash
api_url = https://<id>.execute-api.<region>.amazonaws.com/prod/predict
```

## Cleanup

```bash
terraform destroy
```

## Notes

* Serverless max memory: 6 GB
* No GPU support
* Model routing handled inside container

## Future Improvements

* Least-privilege IAM
* Multi-environment support
* CI/CD integration

