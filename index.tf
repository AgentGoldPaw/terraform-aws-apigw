terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67"
    }
  }
}

resource "aws_apigatewayv2_api" "api" {
  name          = var.name
  protocol_type = var.type

  dynamic "cors_configuration" {
    for_each = var.cors != null ? [1] : []
    content {
      allow_headers = var.cors.allow_headers
      allow_methods = var.cors.allow_methods
      allow_origins = var.cors.allow_origins
      max_age       = var.cors.max_age
      expose_headers = vars.cors.expose_headers
    }
  }
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.stage
  auto_deploy = var.auto_deploy
}


resource "aws_apigatewayv2_api_mapping" "map_domain" {
  count       = local.custom_domain
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.domain[0].id
  stage       = aws_apigatewayv2_stage.stage.name
}

resource "aws_apigatewayv2_domain_name" "domain" {
  count       = local.custom_domain
  domain_name = var.api_domain
  domain_name_configuration {
    certificate_arn = local.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}