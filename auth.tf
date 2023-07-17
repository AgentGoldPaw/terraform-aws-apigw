resource "null_resource" "lambda_dependencies" {
  provisioner "local-exec" {
    command = "cd ${local.auth_module} && npm install"
  }

  triggers = {
    index = sha256(file("${local.auth_module}/dist/index.js"))
    package = sha256(file("${local.auth_module}/package.json"))
    lock = sha256(file("${local.auth_module}/package-lock.json"))
    node = sha256(join("",fileset(local.auth_module, "dist/**/*.js")))
  }
}

data "null_data_source" "wait_for_lambda_exporter" {
  inputs = {
    lambda_dependency_id = "${null_resource.lambda_dependencies.id}"
    source_dir           = "${local.auth_module}"
  }
}

data "archive_file" "lambda" {
  count       = var.auth_type == "API_KEY" ? 1 : 0
  output_path = "${path.module}/packaged/auth.zip"
  source_dir  = "${data.null_data_source.wait_for_lambda_exporter.outputs["source_dir"]}"
  type        = "zip"
}

resource "aws_secretsmanager_secret" "api_key" {
  count = var.auth_type == "API_KEY" ? 1 : 0
  name  = "${var.name}-api-key"
}

resource "aws_secretsmanager_secret_version" "api_key" {
  count         = var.auth_type == "API_KEY" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.api_key[0].id
  secret_string = var.api_key
}

resource "aws_iam_role" "authorizer_role" {
  count              = var.auth_type == "API_KEY" ? 1 : 0
  name               = "${var.name}-authorizer-role"
  assume_role_policy = data.aws_iam_policy_document.authorizer_role[0].json
}

resource "aws_iam_policy" "authorizer_policy" {
  count  = var.auth_type == "API_KEY" ? 1 : 0
  name   = "${var.name}-authorizer-policy"
  policy = data.aws_iam_policy_document.authorizer_policy[0].json
}

resource "aws_iam_role_policy_attachment" "authorizer_policy" {
  count      = var.auth_type == "API_KEY" ? 1 : 0
  role       = aws_iam_role.authorizer_role[0].name
  policy_arn = aws_iam_policy.authorizer_policy[0].arn
}

module "auth_function" {
  count    = var.auth_type == "API_KEY" ? 1 : 0
  source   = "RedMunroe/lambda/aws"
  filename = data.archive_file.lambda[0].output_path
  source_code_hash = data.archive_file.lambda[0].output_base64sha256
  name     = "${replace(var.name, ".", "-")}-authorizer"
  permissions = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }, 
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.api_key[0].arn
      },
    ]
  })
  handler = "dist/index.handler"
  environment = {
    SECRET_NAME    = aws_secretsmanager_secret.api_key[0].name
    API_KEY_HEADER = "x-api-key"
  }
  runtime          = "nodejs16.x"
  timeout          = 10
  memory_size      = 128
  tracing_config   = true
  function_type    = "APIGW"
}