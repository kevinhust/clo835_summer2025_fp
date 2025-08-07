terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "clo835fp-bg-images"
    key            = "terraform-state/clo835fp/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "IDlock"
    encrypt        = true
  }
}