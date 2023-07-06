resource "aws_acm_certificate" "certificate" {
  count             = local.custom_cert
  domain_name       = var.api_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  count           = local.custom_cert
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.certificate[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.certificate[0].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.certificate[0].domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.zone[0].zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = local.custom_cert
  certificate_arn         = aws_acm_certificate.certificate[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}


resource "aws_route53_record" "sub_domain" {
  name    = var.api_domain
  type    = "A"
  zone_id = data.aws_route53_zone.zone[0].zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.domain[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.domain[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}