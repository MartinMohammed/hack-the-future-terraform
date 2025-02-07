resource "aws_cloudfront_origin_access_control" "cf-s3-oac" {
  name                              = "CloudFront S3 OAC"
  description                       = "CloudFront S3 OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Point to S3 bucket for web app as origin, with default cache behavior and SSL enabled 
resource "aws_cloudfront_distribution" "web_app_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.web_app_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.web_app_bucket.id
    origin_access_control_id = aws_cloudfront_origin_access_control.cf-s3-oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.web_app_bucket.id
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    # no restrictions
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}

# Create an origin access identity for the web app distribution
resource "aws_cloudfront_origin_access_identity" "web_app_origin_access_identity" {
  comment = "Origin Access Identity for ${aws_s3_bucket.web_app_bucket.bucket}"
}

