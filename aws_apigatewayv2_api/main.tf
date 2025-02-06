resource "aws_apigatewayv2_api" "main" {
  name          = "my-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers  = ["*"]
    allow_methods  = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_origins  = ["*"]
    expose_headers = ["*"]
    max_age        = 3600
  }
} 
