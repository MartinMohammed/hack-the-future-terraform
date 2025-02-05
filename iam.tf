# Create IAM inline policy for S3 access
resource "aws_iam_role_policy" "mwaa_s3_policy" {
  name = "mwaa-s3-policy"
  role = module.mwaa.mwaa_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:ListBucket",
          "s3:PutObject*",
        ]
        # restrict access to the bucket
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.bnetz_s3_bucket.id}/*",
        ]
      }
    ]
  })
}

# Create IAM inline policy for AWS Batch access
resource "aws_iam_role_policy" "mwaa_batch_policy" {
  name = "mwaa-batch-policy"
  role = module.mwaa.mwaa_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "batch:SubmitJob",
          "batch:DescribeJobs",
          "batch:TerminateJob",
          "batch:ListJobs",
          "batch:DescribeJobQueues",
          "batch:DescribeJobDefinitions"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create IAM inline policy for Snowflake S3 access
resource "aws_iam_role_policy" "snowflake_s3_policy" {
  name = "snowflake-s3-policy"
  role = module.mwaa.mwaa_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.bnetz_s3_bucket.id}/data/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.bnetz_s3_bucket.id}"
        Condition = {
          StringLike = {
            "s3:prefix" = ["data/*"]
          }
        }
      }
    ]
  })
}

# Create IAM role for Snowflake
resource "aws_iam_role" "snowflake_role" {
  name = "snowflake-role"

  # Trust relationship policy allowing Snowflake to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::80750740-1405:root" # Replace with Snowflake's AWS account ID
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "PLACEHOLDER_EXTERNAL_ID" # Replace with Snowflake's external ID
          }
        }
      }
    ]
  })

  tags = {
    Purpose = "Snowflake Integration"
  }
}

# Attach the Snowflake S3 policy to the Snowflake role
resource "aws_iam_role_policy_attachment" "snowflake_policy_attachment" {
  role       = aws_iam_role.snowflake_role.name
  policy_arn = aws_iam_role_policy.snowflake_s3_policy.name
}
