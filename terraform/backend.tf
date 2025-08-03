# Terraform configuration
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Note: Using local state for simplicity
# In production, you would configure S3 backend after creating the bucket