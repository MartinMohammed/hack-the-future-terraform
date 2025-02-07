
// Create SSL certificate
resource "aws_acm_certificate" "ssl_cert" {
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
