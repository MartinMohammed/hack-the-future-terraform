terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    encrypt = true
    # dynamodb_table = "terraform-state-lock-dynamo"
    bucket = "terraform-s3-state-hack-the-future-hackathon"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}


provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "GameJam"
      Environment = var.environment
      Terraform   = "true"
      ManagedBy   = "Terraform"
    }
  }
}
