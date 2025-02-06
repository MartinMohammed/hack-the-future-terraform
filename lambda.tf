resource "aws_lambda_function" "tariff_handler" {
  function_name = "tariff_handler"
  # use local file
  filename = "${path.module}/dist/handlers/tariff_handler.zip"

  handler     = "index.handler"
  runtime     = "nodejs18.x"
  memory_size = 1024
  timeout     = 300
  environment {
    variables = {
      SNOWFLAKE_SECRET_NAME = aws_secretsmanager_secret.snowflake_secret.name
      AWS_REGION            = var.aws_region
    }
  }

  source_code_hash = filebase64sha256("${path.module}/dist/handlers/tariff_handler.zip")

  layers = [
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]

  role = aws_iam_role.handler_lambda_exec.arn
}
