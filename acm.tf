# reference existing ACM certificate
data "aws_acm_certificate" "ssl_cert" {
  provider = aws.us_east
  domain   = var.domain
  statuses = ["ISSUED"]
}

