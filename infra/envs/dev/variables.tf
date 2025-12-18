variable "aws_region" {
  type        = string
  description = "AWS region for the deployment."
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, prod)."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must use lowercase alphanumeric characters or hyphen."
  }
}

variable "service_name" {
  type        = string
  description = "Service name used in tagging and resource naming."

  validation {
    condition     = length(var.service_name) >= 3
    error_message = "Service name must be at least 3 characters."
  }
}

variable "artifact_bucket_name" {
  type        = string
  description = "Name for the Lambda artifact S3 bucket."
}

variable "artifact_bucket_sse_algorithm" {
  type        = string
  default     = "aws:kms"
  description = "SSE algorithm for the artifact bucket."

  validation {
    condition     = contains(["aws:kms", "AES256"], var.artifact_bucket_sse_algorithm)
    error_message = "SSE algorithm must be aws:kms or AES256."
  }
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table."
}

variable "dynamodb_hash_key" {
  type        = string
  description = "Primary partition key name."
}

variable "dynamodb_hash_key_type" {
  type        = string
  default     = "S"
  description = "Attribute type for the partition key."

  validation {
    condition     = contains(["S", "N", "B"], var.dynamodb_hash_key_type)
    error_message = "Partition key type must be S, N, or B."
  }
}

variable "dynamodb_range_key" {
  type        = string
  default     = null
  description = "Optional sort key name."
}

variable "dynamodb_range_key_type" {
  type        = string
  default     = "S"
  description = "Attribute type for the sort key."

  validation {
    condition     = contains(["S", "N", "B"], var.dynamodb_range_key_type)
    error_message = "Sort key type must be S, N, or B."
  }
}

variable "dynamodb_billing_mode" {
  type        = string
  default     = "PAYPERREQUEST"
  description = "Billing mode for the table."

  validation {
    condition     = contains(["PAYPERREQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be PAYPERREQUEST or PROVISIONED."
  }
}

variable "dynamodb_kms_key_arn" {
  type        = string
  default     = null
  description = "Optional KMS key ARN for DynamoDB."
}

variable "log_group_names" {
  type        = list(string)
  description = "List of CloudWatch Log Group names for Lambda functions."

  validation {
    condition     = length(var.log_group_names) > 0
    error_message = "Provide at least one log group name."
  }
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Number of days to retain Lambda logs."

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "Retention must be between 1 and 3653 days."
  }
}

variable "logs_kms_key_id" {
  type        = string
  default     = null
  description = "Optional KMS key for log encryption."
}

variable "lambda_role_name" {
  type        = string
  description = "Name of the IAM role used by Lambda functions."

  validation {
    condition     = can(regex("^[A-Za-z0-9+=,.@_-]+$", var.lambda_role_name))
    error_message = "Role name contains invalid characters."
  }
}

variable "lambda_log_level" {
  type        = string
  default     = "info"
  description = "Minimum log level emitted by the Lambda function."

  validation {
    condition     = contains(["debug", "info", "warn", "error"], lower(var.lambda_log_level))
    error_message = "Log level must be one of debug, info, warn, error."
  }
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function."
}

variable "lambda_description" {
  type        = string
  default     = "Serverless REST API handler."
  description = "Description text for the Lambda function."
}

variable "lambda_source_dir" {
  type        = string
  default     = "../../functions/items"
  description = "Relative path to the Lambda source directory."
}

variable "lambda_artifact_prefix" {
  type        = string
  default     = "lambda"
  description = "Prefix used for Lambda artifacts stored in S3."
}

variable "lambda_memory_size" {
  type        = number
  default     = 256
  description = "Lambda memory allocation in MB."

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Memory must be between 128 and 10240 MB."
  }
}

variable "lambda_timeout" {
  type        = number
  default     = 10
  description = "Lambda timeout in seconds."

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_environment_variables" {
  type        = map(string)
  default     = {}
  description = "Extra environment variables injected into the Lambda function."
}

variable "lambda_additional_statements" {
  description = "Optional additional IAM policy statements."
  type = list(object({
    sid       = optional(string)
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags merged into every resource."
}

variable "api_name" {
  type        = string
  default     = "serverless-rest-api"
  description = "Friendly name for the API Gateway REST API."
}

variable "api_stage_name" {
  type        = string
  default     = null
  description = "Override for the API Gateway stage name. Defaults to the environment when null."
}

variable "cors_allowed_origins" {
  type        = list(string)
  default     = ["*"]
  description = "CORS allowed origins exposed by API Gateway."

  validation {
    condition     = length(var.cors_allowed_origins) > 0
    error_message = "At least one allowed origin is required."
  }
}

variable "cors_allowed_headers" {
  type        = list(string)
  default     = ["Content-Type", "Authorization"]
  description = "Headers returned in Access-Control-Allow-Headers."
}

variable "cors_allowed_methods" {
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  description = "Methods returned in Access-Control-Allow-Methods."
}

variable "event_lambda_role_name" {
  type        = string
  description = "IAM role name for the scheduled EventBridge Lambda."
}

variable "event_lambda_function_name" {
  type        = string
  description = "Name of the scheduled EventBridge Lambda."
}

variable "event_lambda_description" {
  type        = string
  default     = "EventBridge-driven background processor."
  description = "Description for the event Lambda."
}

variable "event_lambda_source_dir" {
  type        = string
  default     = "../../functions/event-processor"
  description = "Path to the event Lambda source code."
}

variable "event_lambda_artifact_prefix" {
  type        = string
  default     = "event-lambda"
  description = "Prefix used for event Lambda artifacts stored in S3."
}

variable "event_lambda_memory_size" {
  type        = number
  default     = 256
  description = "Memory allocation for the event Lambda."
}

variable "event_lambda_timeout" {
  type        = number
  default     = 15
  description = "Timeout in seconds for the event Lambda."
}

variable "event_lambda_environment_variables" {
  type        = map(string)
  default     = {}
  description = "Additional env vars injected into the event Lambda."
}

variable "event_lambda_schedule_expression" {
  type        = string
  description = "Cron or rate expression for the EventBridge schedule."
}

variable "event_dlq_queue_name" {
  type        = string
  description = "Name of the SQS queue used as the EventBridge dead-letter queue."
}

variable "monitoring_alarm_actions" {
  type        = list(string)
  default     = []
  description = "List of ARNs to notify when CloudWatch alarms fire."
}

variable "lambda_latency_threshold" {
  type        = number
  default     = 1000
  description = "p95 duration threshold (milliseconds) before the Lambda latency alarm fires."
}

variable "lambda_error_threshold" {
  type        = number
  default     = 1
  description = "Number of Lambda errors per evaluation window before alarming."
}

variable "lambda_throttle_threshold" {
  type        = number
  default     = 1
  description = "Number of throttled Lambda invocations before alarming."
}
