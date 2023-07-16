resource "aws_secretsmanager_secret" "api_key" {
  count = var.auth_type == "API_KEY" ? 1 : 0
  name  = "${var.name}-api-key"
}

resource "aws_secretsmanager_secret_version" "api_key" {
  count         = var.auth_type == "API_KEY" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = var.api_key
}

module "auth_function" {
  source   = "RedMunroe/lambda/aws"
  filename = ""
  name     = "${var.name}-auth"
  permissions = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.api_key.arn
      },
    ]
  })
  handler          = "index.handler"
  environment      = "$default"
  runtime          = "nodejs16.x"
  timeout          = 10
  memory_size      = 128
  source_code_hash = var.functions[count.index].function.source_code_hash
  tracing_config   = var.functions[count.index].function.tracing_config
  function_type    = "APIGW"
}