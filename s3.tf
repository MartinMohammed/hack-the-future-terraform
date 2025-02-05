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
