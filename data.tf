data "aws_route53_zone" "zone" {
  count = local.custom_domain
  name  = "${var.domain}."
}