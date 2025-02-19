
# ---------------------------------------------------------------------------------------------------------------------
# tariffs handler
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "tariffs_handler" {
  function_name = "tariffs_handler"
  # use local file
  filename = "${path.module}/dist/handlers/tariffs_handler.zip"

  handler     = "index.handler"
  runtime     = "nodejs18.x"
  memory_size = 1024
  timeout     = 300
  environment {
    variables = {
      SNOWFLAKE_SECRET_NAME = aws_secretsmanager_secret.snowflake_secret.name
    }
  }

  source_code_hash = filebase64sha256("${path.module}/dist/handlers/tariffs_handler.zip")

  layers = [
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]

  role = aws_iam_role.handler_lambda_exec.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# tariff handler
# ---------------------------------------------------------------------------------------------------------------------
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
    }
  }

  source_code_hash = filebase64sha256("${path.module}/dist/handlers/tariff_handler.zip")

  layers = [
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]

  role = aws_iam_role.handler_lambda_exec.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# bonis handler
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "bonis_handler" {
  function_name = "bonis_handler"
  # use local file
  filename = "${path.module}/dist/handlers/bonis_handler.zip"

  handler     = "index.handler"
  runtime     = "nodejs18.x"
  memory_size = 1024
  timeout     = 300
  environment {
    variables = {
      SNOWFLAKE_SECRET_NAME = aws_secretsmanager_secret.snowflake_secret.name
    }
  }

  source_code_hash = filebase64sha256("${path.module}/dist/handlers/bonis_handler.zip")

  layers = [
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]

  role = aws_iam_role.handler_lambda_exec.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# load_s3_data_to_snowflake handler
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "load_s3_data_to_snowflake" {
  function_name = "load_s3_data_to_snowflake"
  # use local file
  filename = "${path.module}/dist/lambdas/load_s3_data_to_snowflake.zip"

  handler     = "index.handler"
  runtime     = "nodejs18.x"
  memory_size = 1024
  timeout     = 300
  environment {
    variables = {
      SNOWFLAKE_SECRET_NAME = aws_secretsmanager_secret.snowflake_secret.name
      SNOWFLAKE_STAGE_REF   = var.snowflake_stage_ref
    }
  }

  source_code_hash = filebase64sha256("${path.module}/dist/lambdas/load_s3_data_to_snowflake.zip")

  layers = [
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]

  role = aws_iam_role.handler_lambda_exec.arn
}

