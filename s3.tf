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

# Create S3 bucket for MWAA
resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = "hack-the-future-mwaa-${var.environment}"
}

# Enable versioning for the MWAA bucket
resource "aws_s3_bucket_versioning" "mwaa_bucket_versioning" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


# Block public access to the MWAA bucket
resource "aws_s3_bucket_public_access_block" "mwaa_bucket_public_access_block" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
