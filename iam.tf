
# Create IAM role for MWAA
resource "aws_iam_role" "mwaa_execution_role" {
  name = "mwaa-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "airflow.amazonaws.com",
            "airflow-env.amazonaws.com"
          ]
        }
      }
    ]
  })
}

# Create IAM inline policy for S3 access
resource "aws_iam_role_policy" "mwaa_s3_policy" {
  name = "mwaa-s3-policy"
  role = aws_iam_role.mwaa_execution_role.id

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
          "arn:aws:s3:::${module.hack-the-future-mwaa.aws_s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# Create IAM inline policy for AWS Batch access
resource "aws_iam_role_policy" "mwaa_batch_policy" {
  name = "mwaa-batch-policy"
  role = aws_iam_role.mwaa_execution_role.id

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
