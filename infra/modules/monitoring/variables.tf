variable "environment" {
  type        = string
  description = "Deployment environment label."
}

variable "service_name" {
  type        = string
  description = "Service identifier for tagging and dashboards."
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function to monitor."
}

variable "api_gateway_id" {
  type        = string
  description = "REST API ID for API Gateway metrics."
}

variable "api_stage_name" {
  type        = string
  description = "Stage name for API Gateway metrics."
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table to monitor."
}

variable "alarm_actions" {
  type        = list(string)
  default     = []
  description = "List of ARNs (SNS topics, etc.) to notify when alarms trigger."
}

variable "lambda_latency_threshold" {
  type        = number
  default     = 1000
  description = "p95 duration threshold in milliseconds that triggers the latency alarm."
}

variable "lambda_error_threshold" {
  type        = number
  default     = 1
  description = "Number of errors within the evaluation window that triggers the error alarm."
}

variable "lambda_throttle_threshold" {
  type        = number
  default     = 1
  description = "Number of throttled invocations before alarming."
}

variable "dlq_queue_name" {
  type        = string
  default     = null
  description = "Optional SQS DLQ name to monitor."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to monitoring resources."
}
