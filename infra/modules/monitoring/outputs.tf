output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.service.dashboard_name
}

output "lambda_error_alarm_arn" {
  description = "ARN of the Lambda error alarm."
  value       = aws_cloudwatch_metric_alarm.lambda_errors.arn
}

output "lambda_latency_alarm_arn" {
  description = "ARN of the Lambda latency alarm."
  value       = aws_cloudwatch_metric_alarm.lambda_latency.arn
}

output "lambda_throttle_alarm_arn" {
  description = "ARN of the Lambda throttle alarm."
  value       = aws_cloudwatch_metric_alarm.lambda_throttles.arn
}

output "dlq_alarm_arn" {
  description = "ARN of the DLQ backlog alarm (if configured)."
  value       = try(aws_cloudwatch_metric_alarm.dlq_backlog[0].arn, null)
}
