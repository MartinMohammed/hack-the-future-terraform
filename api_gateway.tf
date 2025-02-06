# version 2 allows us to create restful apis
resource "aws_apigatewayv2_api" "main" {
  name          = "hack-the-future-bnetz-api"
  protocol_type = "HTTP"
}


# stage is the deployment environment
resource "aws_apigatewayv2_stage" "dev" {
  api_id = aws_apigatewayv2_api.main.id

  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.main_api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

# forward requests to the lambda function
resource "aws_apigatewayv2_integration" "tariffs_handler" {
  api_id = aws_apigatewayv2_api.main.id

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.tariffs_handler.invoke_arn
}

resource "aws_apigatewayv2_route" "tariffs_handler" {
  api_id = aws_apigatewayv2_api.main.id
  # allow all http methodss
  route_key = "GET /tariffs"

  target = "integrations/${aws_apigatewayv2_integration.tariffs_handler.id}"
}

# allows api gateway to execute to invoke the lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromHackTheFutureBnetzAPI"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tariffs_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}


# forward requests to the lambda function
resource "aws_apigatewayv2_integration" "tariff_handler" {
  api_id = aws_apigatewayv2_api.main.id

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.tariff_handler.invoke_arn
}

resource "aws_apigatewayv2_route" "tariff_handler" {
  api_id = aws_apigatewayv2_api.main.id
  # allow all http methods
  route_key = "GET /tariff/{tariff_id}"

  target = "integrations/${aws_apigatewayv2_integration.tariff_handler.id}"
}

# allows api gateway to execute to invoke the lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromHackTheFutureBnetzAPI"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tariff_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
