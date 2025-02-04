terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dynamo"
    bucket         = "terraform-s3-state-hack-the-future-hackathon"
    key            = "terraform.tfstate"
    region         = "us-west-2"
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


resource "aws_s3_bucket" "tf_course" {

  bucket = "terraform-s3-state-hack-the-future-hackathon"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_course.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "terraform-state-lock-dynamo"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
