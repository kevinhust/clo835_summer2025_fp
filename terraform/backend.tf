terraform {
  backend "s3" {
    bucket         = "clo835fp-terraform-state"
    key            = "terraform_state/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "clo835fp-terraform-lock"
    encrypt        = true
  }
}