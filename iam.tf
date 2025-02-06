# Create IAM inline policy for S3 access
resource "aws_iam_role_policy" "mwaa_s3_policy" {
  name = "mwaa-s3-policy"
  role = module.mwaa.mwaa_role_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject*",
          "s3:PutObject*"
        ],
        Resource = "arn:aws:s3:::${aws_s3_bucket.bnetz_s3_bucket.id}/*"
      },
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = "arn:aws:s3:::${aws_s3_bucket.bnetz_s3_bucket.id}"
      }
    ]
  })
}
resource "aws_iam_role_policy" "mwaa_lambda_invoke" {
  name = "MWAA-LambdaInvokePolicy"
  role = module.mwaa.mwaa_role_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Sid      = "AllowLambdaInvoke",
        Action   = "lambda:InvokeFunction",
        Resource = "*"
      }
    ]
  })
}

# Create IAM inline policy for Snowflake S3 access
resource "aws_iam_role_policy" "snowflake_s3_policy" {
  name = "snowflake-s3-policy"
  role = aws_iam_role.snowflake_role.name

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
    # comment out principal and external id related stuff 

    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::888577042993:user/ncyu0000-s" # Replace with Snowflake's AWS account ID
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "YG35686_SFCRole=3_3vO8Qx00v4BL8AxZWaedrM6A+hE=" # Replace with Snowflake's external ID
          }
        }
      }
    ]
  })

  tags = {
    Purpose = "Snowflake Integration"
  }
}

resource "aws_iam_role" "handler_lambda_exec" {
  name = "handler-lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "handler_lambda_policy" {
  role = aws_iam_role.handler_lambda_exec.name
  # necessary permissions to run such as logging
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# attachment for aws managed read and write access to secrets manager
resource "aws_iam_role_policy_attachment" "snowflake_secret_manager_policy" {
  role       = aws_iam_role.handler_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

