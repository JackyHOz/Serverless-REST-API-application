locals {
  log_groups = { for name in var.log_group_names : name => name }
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each          = local.log_groups
  name              = each.value
  kms_key_id        = var.kms_key_id
  retention_in_days = var.retention_in_days

  tags = merge(
    {
      "Environment" = var.environment
      "Service"     = var.service_name
    },
    var.tags,
  )
}
