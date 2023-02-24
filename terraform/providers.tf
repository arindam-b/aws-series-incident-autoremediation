# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Terraform state file
terraform {
  backend "s3" {
    bucket = "infra-states-backend-tekincloud"
    key    = "terraform-states/lambda-auto-remediation"
    region = "us-east-1"
  }
}

