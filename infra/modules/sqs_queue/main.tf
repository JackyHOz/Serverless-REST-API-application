resource "aws_sqs_queue" "this" {
  name                       = var.name
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  sqs_managed_sse_enabled    = var.encryption_enabled
  tags                       = var.tags
}
