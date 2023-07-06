locals {
  custom_domain   = var.domain != "" ? 1 : 0
  custom_cert     = var.certificate_arn == "" ? 1 : 0
  certificate_arn = local.custom_cert == 0 ? var.certificate_arn : aws_acm_certificate.certificate[0].arn
}