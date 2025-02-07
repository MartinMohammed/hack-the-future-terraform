# create a route53 zone for my domain therealfriends.de
resource "aws_route53_zone" "therealfriends_zone" {
  name = "therealfriends.de"
}

# # Create an alias record pointing to the CloudFront distribution using prod subdomain
# resource "aws_route53_record" "web_app_record" {
#   zone_id = aws_route53_zone.therealfriends_zone.zone_id
#   name    = "prod.therealfriends.de"
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.web_app_distribution.domain_name
#     zone_id                = aws_cloudfront_distribution.web_app_distribution.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
