##############################################
# Terraform + Provider Version Constraints
##############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"   # Pin to AWS provider v6.x
    }
  }

  required_version = ">= 1.3.0"   # Optional but recommended
}

##############################################
# AWS Provider Configuration
##############################################

provider "aws" {
  region = var.region
}
