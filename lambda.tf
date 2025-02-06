resource "aws_lambda_function" "tariff_handler" {
  function_name = "tariff_handler"
  filename      = "src/handlers/tariff_handler.zip"

  handler     = "index.handler"
  runtime     = "nodejs18.x"
  memory_size = 1024
  timeout     = 300

  # This will force Terraform to update the Lambda when the zip content changes
  source_code_hash = filebase64sha256("src/handlers/tariff_handler.zip")

  role = aws_iam_role.handler_lambda_exec.arn
}
