##############################################
# AWS Identity & Environment Metadata
##############################################

# Account + caller (user / role / SSO session)
data "aws_caller_identity" "current" {}

# Region where resources are deployed
data "aws_region" "current" {}

# Partition (aws / aws-cn / aws-us-gov)
data "aws_partition" "current" {}
