variable "role_name" {
  type        = string
  description = "Name of the IAM role."
}

variable "environment" {
  type        = string
  description = "Deployment environment label."
}

variable "service_name" {
  type        = string
  description = "Service identifier for tagging."
}

variable "assume_role_services" {
  type        = list(string)
  default     = ["lambda.amazonaws.com"]
  description = "AWS services that can assume the role."
}

variable "dynamodb_table_arn" {
  type        = string
  default     = null
  description = "ARN of the DynamoDB table the Lambda can access."
}

variable "log_group_arns" {
  type        = list(string)
  default     = []
  description = "List of log group ARNs granting logging permissions."
}

variable "artifact_bucket_arn" {
  type        = string
  default     = null
  description = "ARN of the Lambda artifact S3 bucket."
}

variable "additional_statements" {
  description = "Optional extra IAM statements to include."
  type = list(object({
    sid       = optional(string)
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply."
}
