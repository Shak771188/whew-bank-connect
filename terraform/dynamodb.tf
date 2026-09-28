resource "aws_dynamodb_table" "plaid_items" {
  name         = "whew-plaid-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Project = "whew-bank-connect"
  }
}
