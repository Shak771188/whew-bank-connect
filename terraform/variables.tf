variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "plaid_client_id" {
  description = "Plaid client ID (from dashboard.plaid.com)"
  type        = string
  sensitive   = true
}

variable "plaid_secret" {
  description = "Plaid secret key for the chosen environment"
  type        = string
  sensitive   = true
}

variable "plaid_env" {
  description = "Plaid environment: sandbox, development, or production"
  type        = string
  default     = "sandbox"
}

variable "allowed_origin" {
  description = "Origin allowed to call this API (your frontend's URL). Use * for local dev."
  type        = string
  default     = "*"
}
