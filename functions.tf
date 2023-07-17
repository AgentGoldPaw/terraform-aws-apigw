module "functions" {
  count            = var.functions != null ? length(var.functions) : 0
  source           = "RedMunroe/lambda/aws"
  filename         = var.functions[count.index].function.filename
  name             = var.functions[count.index].function.name
  permissions      = var.functions[count.index].permissions
  handler          = var.functions[count.index].function.handler
  environment      = var.functions[count.index].function.environment
  runtime          = var.functions[count.index].function.runtime
  timeout          = var.functions[count.index].function.timeout
  memory_size      = var.functions[count.index].function.memory_size
  source_code_hash = var.functions[count.index].function.source_code_hash
  tracing_config   = var.functions[count.index].function.tracing_config
  function_type    = "APIGW"
}

resource "aws_lambda_permission" "the-function-api-gateway" {
  count         = length(module.functions)
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.functions[count.index].name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_stage.stage.execution_arn}/${var.functions[count.index].api.method}${var.functions[count.index].api.route}"
}

resource "aws_apigatewayv2_integration" "integration" {
  count              = length(module.functions)
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = module.functions[count.index].invoke_arn
}

resource "aws_apigatewayv2_route" "route" {
  count              = length(aws_apigatewayv2_integration.integration)
  api_id             = aws_apigatewayv2_api.api.id
  authorization_type = var.auth_type == "JWT" ? "JWT" : "CUSTOM"
  authorizer_id      = var.auth_type == "JWT" ? aws_apigatewayv2_authorizer.api_authorizer[0].id : aws_apigatewayv2_authorizer.api_authorizer2[0].id
  route_key          = "${var.functions[count.index].api.method} ${var.functions[count.index].api.route}"
  target             = "integrations/${aws_apigatewayv2_integration.integration[count.index].id}"
}


