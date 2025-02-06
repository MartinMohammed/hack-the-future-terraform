# point to s3 bucket for web app as origin, default cache behaviour and ssl enabled 
resource "aws_cloudfront_distribution" "web_app_distribution" {
  origin {
    domain_name = aws_s3_bucket.web_app_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.web_app_bucket.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_app_origin_access_identity.cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.web_app_bucket.bucket_regional_domain_name
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    max_ttl                = 3600
    forwarded_values {
      query_string = false
      headers      = ["Host"]
      cookies {
        forward = "none"
      }
    }
  }

  # Optionally, specify a default root object if needed:
  # default_root_object = "index.html"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  enabled = true

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

}

# create origin access identity for web app distribution
resource "aws_cloudfront_origin_access_identity" "web_app_origin_access_identity" {
  comment = "Origin Access Identity for ${aws_s3_bucket.web_app_bucket.bucket}"
}

