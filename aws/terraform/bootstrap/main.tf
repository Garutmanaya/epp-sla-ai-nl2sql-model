##############################################
# Bootstrap: S3 + DynamoDB for Terraform state
##############################################

provider "aws" {
  region = "us-east-1"
}

##############################################
# S3 Bucket for Terraform State
##############################################

resource "aws_s3_bucket" "tf_state" {
  bucket = "epp-sla-reporter-text2sql-tf-state-bucket"
}

##############################################
# Enable Versioning (important)
##############################################

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

##############################################
# Server-side Encryption
##############################################

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

##############################################
# Block Public Access (security best practice)
##############################################

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##############################################
# DynamoDB Table for State Locking
##############################################

resource "aws_dynamodb_table" "tf_locks" {
  name         = "epp-sla-reporter-text2sql-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

##############################################
# Outputs
##############################################

output "bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.tf_locks.name
}
