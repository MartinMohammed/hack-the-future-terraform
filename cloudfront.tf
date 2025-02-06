locals {
  s3_origin_id   = "${aws_s3_bucket.web_app_bucket.bucket}-origin"
  s3_domain_name = aws_s3_bucket.web_app_bucket.bucket_regional_domain_name
}

# Point to S3 bucket for web app as origin, with default cache behavior and SSL enabled 
resource "aws_cloudfront_distribution" "web_app_distribution" {
  enabled = true

  origin {
    domain_name = local.s3_domain_name
    origin_id   = local.s3_origin_id

    // Use s3_origin_config for an S3 bucket origin with an origin access identity
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_app_origin_access_identity.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id = local.s3_origin_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_200"
}

# Create an origin access identity for the web app distribution
resource "aws_cloudfront_origin_access_identity" "web_app_origin_access_identity" {
  comment = "Origin Access Identity for ${aws_s3_bucket.web_app_bucket.bucket}"
}

