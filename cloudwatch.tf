# cloudwatch log group for the api gateway
resource "aws_cloudwatch_log_group" "main_api_gw" {
  name = "/aws/api-gw/${aws_apigatewayv2_api.main.name}"

  retention_in_days = 30
}

# one cloudwatch log group for each lambda function
resource "aws_cloudwatch_log_group" "tariffs_handler_lambda" {
  name = "/aws/lambda/${aws_lambda_function.tariffs_handler.function_name}"
}

# one cloudwatch log group for each lambda function
resource "aws_cloudwatch_log_group" "tariff_handler_lambda" {
  name = "/aws/lambda/${aws_lambda_function.tariff_handler.function_name}"
}


# one cloudwatch log group for each lambda function
resource "aws_cloudwatch_log_group" "load_s3_data_to_snowflake_lambda" {
  name = "/aws/lambda/${aws_lambda_function.load_s3_data_to_snowflake.function_name}"
}
