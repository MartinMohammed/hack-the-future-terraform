resource "aws_lambda_function" "tariff_handler" {
  function_name = "tariff-handler"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.tariff_handler.key

  runtime = "python3.11"
  handler = "function.handler"

  #   source_code_hash = data.archive_file.tariff_handler.output_base64sha256

  role = aws_iam_role.handler_lambda_exec.arn
}
