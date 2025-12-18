variable "log_group_names" {
  type        = list(string)
  description = "List of CloudWatch Log Group names to provision."

  validation {
    condition     = length(var.log_group_names) > 0
    error_message = "At least one log group name must be supplied."
  }
}

variable "retention_in_days" {
  type        = number
  default     = 30
  description = "Retention period for log events."

  validation {
    condition     = var.retention_in_days >= 1 && var.retention_in_days <= 3653
    error_message = "Retention must be between 1 and 3653 days."
  }
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "Optional KMS key for log group encryption."
}

variable "environment" {
  type        = string
  description = "Deployment environment label."
}

variable "service_name" {
  type        = string
  description = "Service identifier for tagging."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply."
}
