variable "function_name" {
  type        = string
  description = "Name of the Lambda function."
}

variable "description" {
  type        = string
  default     = ""
  description = "Description of the Lambda function."
}

variable "handler" {
  type        = string
  default     = "index.handler"
  description = "Entry point for the Lambda handler."
}

variable "runtime" {
  type        = string
  default     = "nodejs22.x"
  description = "Lambda runtime identifier."
}

variable "memory_size" {
  type        = number
  default     = 256
  description = "Amount of memory in MB for the function."

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 MB and 10240 MB."
  }
}

variable "timeout" {
  type        = number
  default     = 10
  description = "Timeout in seconds for the function."

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "architectures" {
  type        = list(string)
  default     = ["arm64"]
  description = "Instruction set architectures supported by the function."
}

variable "role_arn" {
  type        = string
  description = "IAM role ARN assumed by the function."
}

variable "artifact_bucket_name" {
  type        = string
  description = "Name of the S3 bucket where the zipped artifact will be stored."
}

variable "artifact_prefix" {
  type        = string
  default     = "lambda"
  description = "Prefix inside the artifact bucket for uploads."
}

variable "source_dir" {
  type        = string
  description = "Local directory containing the Lambda source code."
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Environment variables injected into the Lambda function."
}

variable "publish" {
  type        = bool
  default     = true
  description = "Controls whether a new version is published on updates."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the Lambda function."
}
