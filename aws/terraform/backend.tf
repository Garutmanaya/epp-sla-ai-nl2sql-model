##############################################
# Remote Backend Configuration
##############################################

terraform {
  backend "s3" {
    bucket         = "epp-sla-reporter-text2sql-tf-state-bucket"   # must exist or be created once
    key            = "sagemaker-serverless/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "epp-sla-reporter-text2sql-tf-locks"
  }
}
