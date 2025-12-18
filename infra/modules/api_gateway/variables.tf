variable "name" {
  type        = string
  description = "Name of the API Gateway REST API."
}

variable "description" {
  type        = string
  default     = ""
  description = "Description for the REST API."
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Invoke ARN of the Lambda integration."
}

variable "lambda_function_arn" {
  type        = string
  description = "Function ARN used in permissions."
}

variable "stage_name" {
  type        = string
  description = "Deployment stage name."
}

variable "cors_allowed_origins" {
  type        = list(string)
  default     = ["*"]
  description = "List of origins allowed via CORS headers."
}

variable "cors_allowed_headers" {
  type        = list(string)
  default     = ["Content-Type", "Authorization"]
  description = "Headers allowed by CORS preflight responses."
}

variable "cors_allowed_methods" {
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  description = "Methods allowed by CORS preflight responses."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to API resources."
}
