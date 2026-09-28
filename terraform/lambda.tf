data "archive_file" "function_package" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/../function.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "whew-bank-connect-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "whew-bank-connect-dynamodb-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem"]
      Resource = aws_dynamodb_table.plaid_items.arn
    }]
  })
}

locals {
  common_env = {
    PLAID_CLIENT_ID = var.plaid_client_id
    PLAID_SECRET    = var.plaid_secret
    PLAID_ENV       = var.plaid_env
    DYNAMODB_TABLE  = aws_dynamodb_table.plaid_items.name
  }
}

resource "aws_lambda_function" "create_link_token" {
  function_name    = "whew-create-link-token"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/createLinkToken.handler"
  runtime          = "nodejs20.x"
  timeout          = 10
  filename         = data.archive_file.function_package.output_path
  source_code_hash = data.archive_file.function_package.output_base64sha256

  environment {
    variables = local.common_env
  }
}

resource "aws_lambda_function" "exchange_public_token" {
  function_name    = "whew-exchange-public-token"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/exchangePublicToken.handler"
  runtime          = "nodejs20.x"
  timeout          = 10
  filename         = data.archive_file.function_package.output_path
  source_code_hash = data.archive_file.function_package.output_base64sha256

  environment {
    variables = local.common_env
  }
}

resource "aws_lambda_function" "get_transactions" {
  function_name    = "whew-get-transactions"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/getTransactions.handler"
  runtime          = "nodejs20.x"
  timeout          = 15
  filename         = data.archive_file.function_package.output_path
  source_code_hash = data.archive_file.function_package.output_base64sha256

  environment {
    variables = local.common_env
  }
}
