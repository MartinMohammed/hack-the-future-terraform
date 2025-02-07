provider "aws" {
  region = "us-east-1"
}

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
