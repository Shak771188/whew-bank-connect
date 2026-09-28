resource "aws_apigatewayv2_api" "whew_api" {
  name          = "whew-bank-connect-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [var.allowed_origin]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.whew_api.id
  name        = "$default"
  auto_deploy = true
}

# --- create-link-token: POST /create-link-token ---
resource "aws_apigatewayv2_integration" "create_link_token" {
  api_id                 = aws_apigatewayv2_api.whew_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_link_token.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_link_token" {
  api_id    = aws_apigatewayv2_api.whew_api.id
  route_key = "POST /create-link-token"
  target    = "integrations/${aws_apigatewayv2_integration.create_link_token.id}"
}

resource "aws_lambda_permission" "create_link_token" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_link_token.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.whew_api.execution_arn}/*/*"
}

# --- exchange-public-token: POST /exchange-public-token ---
resource "aws_apigatewayv2_integration" "exchange_public_token" {
  api_id                 = aws_apigatewayv2_api.whew_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.exchange_public_token.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "exchange_public_token" {
  api_id    = aws_apigatewayv2_api.whew_api.id
  route_key = "POST /exchange-public-token"
  target    = "integrations/${aws_apigatewayv2_integration.exchange_public_token.id}"
}

resource "aws_lambda_permission" "exchange_public_token" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exchange_public_token.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.whew_api.execution_arn}/*/*"
}

# --- get-transactions: GET /transactions ---
resource "aws_apigatewayv2_integration" "get_transactions" {
  api_id                 = aws_apigatewayv2_api.whew_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_transactions.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_transactions" {
  api_id    = aws_apigatewayv2_api.whew_api.id
  route_key = "GET /transactions"
  target    = "integrations/${aws_apigatewayv2_integration.get_transactions.id}"
}

resource "aws_lambda_permission" "get_transactions" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_transactions.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.whew_api.execution_arn}/*/*"
}
