variable "name" {
  type        = string
  description = "Name of the SQS queue."
}

variable "message_retention_seconds" {
  type        = number
  default     = 1209600
  description = "Message retention period (default 14 days)."
}

variable "visibility_timeout_seconds" {
  type        = number
  default     = 30
  description = "Visibility timeout in seconds."
}

variable "encryption_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable SQS managed SSE."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the queue."
}
