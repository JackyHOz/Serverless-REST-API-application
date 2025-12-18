output "artifact_bucket_id" {
  description = "ID of the Lambda artifact bucket."
  value       = module.artifact_bucket.bucket_id
}

output "artifact_bucket_arn" {
  description = "ARN of the Lambda artifact bucket."
  value       = module.artifact_bucket.bucket_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table."
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table."
  value       = module.dynamodb.table_arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by Lambda functions."
  value       = module.iam_lambda_role.role_arn
}

output "log_group_arns" {
  description = "Map of provisioned CloudWatch Log Group ARNs."
  value       = module.logging.log_group_arns
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function."
  value       = module.lambda_function.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function."
  value       = module.lambda_function.function_arn
}

output "api_gateway_id" {
  description = "Identifier of the API Gateway REST API."
  value       = module.api_gateway.rest_api_id
}

output "api_gateway_invoke_url" {
  description = "Invoke URL for the API Gateway stage."
  value       = module.api_gateway.invoke_url
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway stage."
  value       = module.api_gateway.execution_arn
}

output "monitoring_dashboard_name" {
  description = "Name of the CloudWatch dashboard for the service."
  value       = module.monitoring.dashboard_name
}

output "event_lambda_function_name" {
  description = "Name of the scheduled EventBridge Lambda."
  value       = module.event_lambda.function_name
}

output "event_lambda_function_arn" {
  description = "ARN of the scheduled EventBridge Lambda."
  value       = module.event_lambda.function_arn
}

output "eventbridge_rule_name" {
  description = "EventBridge rule name for scheduled processing."
  value       = module.eventbridge_rule.rule_name
}

output "event_dlq_queue_url" {
  description = "URL of the EventBridge dead-letter queue."
  value       = module.event_dlq.queue_url
}
