variable "name" {
  type        = string
  description = "Name of the EventBridge rule."
}

variable "description" {
  type        = string
  default     = ""
  description = "Description for the EventBridge rule."
}

variable "schedule_expression" {
  type        = string
  description = "Schedule expression (cron or rate)."
}

variable "target_arn" {
  type        = string
  description = "ARN of the event target (Lambda)."
}

variable "target_id" {
  type        = string
  default     = "lambda-target"
  description = "Identifier for the EventBridge target."
}

variable "dead_letter_queue_arn" {
  type        = string
  default     = null
  description = "Optional ARN of an SQS queue used as DLQ for failed events."
}

variable "input" {
  type        = string
  default     = null
  description = "Optional JSON payload to send with each event."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the rule."
}
