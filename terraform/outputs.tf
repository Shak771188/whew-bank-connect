output "api_base_url" {
  description = "Base URL to put in your frontend's .env as VITE_BANK_API_URL"
  value       = aws_apigatewayv2_api.whew_api.api_endpoint
}
