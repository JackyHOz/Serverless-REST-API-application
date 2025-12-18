output "log_group_arns" {
  description = "Map of log group ARNs keyed by name."
  value       = { for name, group in aws_cloudwatch_log_group.lambda : name => group.arn }
}
