output "rule_arn" {
  value       = aws_cloudwatch_event_rule.this.arn
  description = "ARN of the EventBridge rule."
}

output "rule_name" {
  value       = aws_cloudwatch_event_rule.this.name
  description = "Name of the EventBridge rule."
}
