variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table."
}

variable "billing_mode" {
  type        = string
  default     = "PAY_PER_REQUEST"
  description = "Billing mode for the table (PAY_PER_REQUEST or PROVISIONED)."

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "hash_key" {
  type        = string
  description = "Primary partition key name."
}

variable "hash_key_type" {
  type        = string
  default     = "S"
  description = "Attribute type for the partition key."

  validation {
    condition     = contains(["S", "N", "B"], var.hash_key_type)
    error_message = "Attribute type must be one of S, N, or B."
  }
}

variable "range_key" {
  type        = string
  default     = null
  description = "Optional sort key name."
}

variable "range_key_type" {
  type        = string
  default     = "S"
  description = "Attribute type for the sort key."

  validation {
    condition     = contains(["S", "N", "B"], var.range_key_type)
    error_message = "Attribute type must be one of S, N, or B."
  }
}

variable "enable_pitr" {
  type        = bool
  default     = true
  description = "Enable point-in-time recovery."
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "Optional KMS key ARN for encryption at rest."
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
