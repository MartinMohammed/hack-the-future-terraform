// Define a separate provider configuration for us-east-1
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

// Create SSL certificate in us-east-1 using the alias provider
resource "aws_acm_certificate" "ssl_cert" {
  provider          = aws.us_east
  domain_name       = var.domain
  validation_method = "DNS"

  tags = {
    Name        = "landing-page"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
