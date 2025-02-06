resource "aws_iam_role_policy" "mwaa_lambda_invoke" {
  name = "MWAA-LambdaInvokePolicy"
  role = aws_iam_role.mwaa_role.name // Ensure this is your MWAA execution role

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowLambdaInvoke",
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = "*" // Optionally restrict to specific Lambda ARNs
      }
    ]
  })
}
