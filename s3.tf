# Create s3 bucket called 'bnetz-s3-bucket
resource "aws_s3_bucket" "bnetz_s3_bucket" {
  bucket = "bnetz-s3-bucket"
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "bnetz_s3_bucket_versioning" {
  bucket = aws_s3_bucket.bnetz_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "random_pet" "lambda_bucket_name" {
  prefix = "lambda"
  length = 2
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = random_pet.lambda_bucket_name.id
  force_destroy = true
}


# ensure that the bucket is not public
resource "aws_s3_bucket_public_access_block" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# create s3 bucket for hosting static content for the web app
# be explicit about website hosting and not rest api

resource "aws_s3_bucket" "web_app_bucket" {
  bucket = "bnetz-web-app-bucket"
}

# enable static website hosting
resource "aws_s3_bucket_website_configuration" "web_app_bucket" {
  bucket = aws_s3_bucket.web_app_bucket.id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# allow public access to the bucket
resource "aws_s3_bucket_public_access_block" "web_app_bucket" {
  bucket = aws_s3_bucket.web_app_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}



