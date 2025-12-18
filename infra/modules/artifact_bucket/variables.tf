variable "bucket_name" {
  type        = string
  description = "Unique name for the artifact bucket"

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket names must be between 3 and 63 characters."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment label (e.g., dev, prod)."
}

variable "enable_versioning" {
  type        = bool
  default     = true
  description = "Determines if S3 bucket versioning is enabled."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "If true, bucket objects will be deleted so the bucket can be destroyed."
}

variable "sse_algorithm" {
  type        = string
  default     = "aws:kms"
  description = "Server-side encryption algorithm for stored objects."

  validation {
    condition     = contains(["aws:kms", "AES256"], var.sse_algorithm)
    error_message = "Supported algorithms are aws:kms and AES256."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional resource tags to apply."
}
