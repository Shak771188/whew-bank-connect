resource "aws_dynamodb_table" "transfers" {
  name         = "whew-transfers"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "transferId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "transferId"
    type = "S"
  }

  tags = {
    Project = "whew-bank-connect"
  }
}

resource "aws_iam_role_policy" "lambda_transfers_dynamodb" {
  name = "whew-bank-connect-transfers-dynamodb-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:Scan"]
      Resource = aws_dynamodb_table.transfers.arn
    }]
  })
}

locals {
  transfer_env = {
    TRANSFERS_TABLE = aws_dynamodb_table.transfers.name
  }
}

resource "aws_lambda_function" "create_transfer_authorization" {
  function_name    = "whew-create-transfer-authorization"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/createTransferAuthorization.handler"
  runtime          = "nodejs20.x"
  timeout          = 10
  filename         = data.archive_file.function_package.output_path
  source_code_hash = data.archive_file.function_package.output_base64sha256

  environment {
    variables = local.transfer_env
  }
}

resource "aws_lambda_function" "create_transfer" {
  function_name    = "whew-create-transfer"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/createTransfer.handler"
  runtime          = "nodejs20.x"
  timeout          = 10
  filename         = data.archive_file.function_package.output_path
  source_code_hash = data.archive_file.function_package.output_base64sha256

  environment {
    variables = local.transfer_env
  }
}

resource "aws_lambda_function" "transfer_webhook" {
  function_name    = "whew-transfer-webhook"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/transferWebhook.handler"
  runtime          = "nodejs20.x"
  timeout          = 10
  filename         = data.archive_file.function_package.output_path
  source_code_hash = data.archive_file.function_package.output_base64sha256

  environment {
    variables = local.transfer_env
  }
}

resource "aws_lambda_function" "get_transfers" {
  function_name    = "whew-get-transfers"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/getTransfers.handler"
  runtime          = "nodejs20.x"
  timeout          = 10
  filename         = data.archive_file.function_package.output_path
  source_code_hash = data.archive_file.function_package.output_base64sha256

  environment {
    variables = local.transfer_env
  }
}

# --- create-transfer-authorization: POST /create-transfer-authorization ---
resource "aws_apigatewayv2_integration" "create_transfer_authorization" {
  api_id                 = aws_apigatewayv2_api.whew_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_transfer_authorization.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_transfer_authorization" {
  api_id    = aws_apigatewayv2_api.whew_api.id
  route_key = "POST /create-transfer-authorization"
  target    = "integrations/${aws_apigatewayv2_integration.create_transfer_authorization.id}"
}

resource "aws_lambda_permission" "create_transfer_authorization" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_transfer_authorization.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.whew_api.execution_arn}/*/*"
}

# --- create-transfer: POST /create-transfer ---
resource "aws_apigatewayv2_integration" "create_transfer" {
  api_id                 = aws_apigatewayv2_api.whew_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_transfer.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_transfer" {
  api_id    = aws_apigatewayv2_api.whew_api.id
  route_key = "POST /create-transfer"
  target    = "integrations/${aws_apigatewayv2_integration.create_transfer.id}"
}

resource "aws_lambda_permission" "create_transfer" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_transfer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.whew_api.execution_arn}/*/*"
}

# --- transfer-webhook: POST /transfer-webhook ---
resource "aws_apigatewayv2_integration" "transfer_webhook" {
  api_id                 = aws_apigatewayv2_api.whew_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.transfer_webhook.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "transfer_webhook" {
  api_id    = aws_apigatewayv2_api.whew_api.id
  route_key = "POST /transfer-webhook"
  target    = "integrations/${aws_apigatewayv2_integration.transfer_webhook.id}"
}

resource "aws_lambda_permission" "transfer_webhook" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transfer_webhook.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.whew_api.execution_arn}/*/*"
}

# --- get-transfers: GET /transfers ---
resource "aws_apigatewayv2_integration" "get_transfers" {
  api_id                 = aws_apigatewayv2_api.whew_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_transfers.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_transfers" {
  api_id    = aws_apigatewayv2_api.whew_api.id
  route_key = "GET /transfers"
  target    = "integrations/${aws_apigatewayv2_integration.get_transfers.id}"
}

resource "aws_lambda_permission" "get_transfers" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_transfers.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.whew_api.execution_arn}/*/*"
}
