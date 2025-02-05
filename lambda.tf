resource "aws_lambda_function" "handler" {
  function_name = "handler"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.handler.key

  runtime = "python3.11"
  handler = "function.handler"

  source_code_hash = data.archive_file.handler.output_base64sha256

  role = aws_iam_role.handler_lambda_exec.arn
}
