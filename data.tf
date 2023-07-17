data "aws_route53_zone" "zone" {
  count = local.custom_domain
  name  = "${var.domain}."
}

data "aws_iam_policy_document" "authorizer_role" {
  count = var.auth_type == "API_KEY" ? 1 : 0
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "authorizer_policy" {
  count = var.auth_type == "API_KEY" ? 1 : 0
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect = "Allow"
    resources = [
      module.auth_function.arn,
    ]
  }
}