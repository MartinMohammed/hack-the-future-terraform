# Create IAM inline policy for S3 access
resource "aws_iam_role_policy" "mwaa_s3_policy" {
  name = "mwaa-s3-policy"
  role = module.mwaa.execution_role_arn

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
  role = module.mwaa.execution_role_arn

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
