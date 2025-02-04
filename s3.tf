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
