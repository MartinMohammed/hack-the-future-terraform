# create a route53 zone for my domain therealfriends.de
resource "aws_route53_zone" "therealfriends_zone" {
  name = "therealfriends.de"
}

# basically creates the NS records for the domain that we need to add to the registrar
# points to the route53 zone for the domain
resource "aws_route53_record" "web_app_record" {
  zone_id = aws_route53_zone.therealfriends_zone.zone_id
  name    = "therealfriends.de"
  type    = "A"
  ttl     = "300"
  records = [aws_cloudfront_distribution.web_app_distribution.domain_name]
}
