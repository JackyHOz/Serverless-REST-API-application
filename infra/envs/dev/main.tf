provider "aws" {
  region = var.aws_region
}

locals {
  base_tags = {
    Environment = var.environment
    Service     = var.service_name
    ManagedBy   = "terraform"
  }

  cors_origin = var.cors_allowed_origins[0]

  lambda_env = merge(
    {
      TABLE_NAME                          = var.dynamodb_table_name
      SERVICE_NAME                        = var.service_name
      ENVIRONMENT                         = var.environment
      LOG_LEVEL                           = var.lambda_log_level
      CORS_ALLOWED_ORIGINS                = local.cors_origin
      AWS_NODEJS_CONNECTION_REUSE_ENABLED = "1"
    },
    var.lambda_environment_variables,
  )

  event_lambda_env = merge(
    {
      TABLE_NAME      = var.dynamodb_table_name
      TABLE_HASH_KEY  = var.dynamodb_hash_key
      TABLE_RANGE_KEY = coalesce(var.dynamodb_range_key, "")
      SERVICE_NAME    = "${var.service_name}-events"
      ENVIRONMENT     = var.environment
      LOG_LEVEL       = var.lambda_log_level
      EVENT_PK_VALUE  = "maintenance#${var.service_name}"
      EVENT_SK_VALUE  = "scheduled-job"
    },
    var.event_lambda_environment_variables,
  )

  api_stage = coalesce(var.api_stage_name, var.environment)
}

module "artifact_bucket" {
  source            = "../../modules/artifact_bucket"
  bucket_name       = var.artifact_bucket_name
  environment       = var.environment
  enable_versioning = true
  force_destroy     = false
  sse_algorithm     = var.artifact_bucket_sse_algorithm
  tags              = merge(local.base_tags, var.additional_tags)
}

module "dynamodb" {
  source         = "../../modules/dynamodb_table"
  table_name     = var.dynamodb_table_name
  hash_key       = var.dynamodb_hash_key
  hash_key_type  = var.dynamodb_hash_key_type
  range_key      = var.dynamodb_range_key
  range_key_type = var.dynamodb_range_key_type
  billing_mode   = var.dynamodb_billing_mode
  enable_pitr    = true
  kms_key_arn    = var.dynamodb_kms_key_arn
  environment    = var.environment
  service_name   = var.service_name
  tags           = merge(local.base_tags, var.additional_tags)
}

module "logging" {
  source            = "../../modules/logging"
  log_group_names   = var.log_group_names
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_id
  environment       = var.environment
  service_name      = var.service_name
  tags              = merge(local.base_tags, var.additional_tags)
}

module "iam_lambda_role" {
  source                = "../../modules/iam_lambda_role"
  role_name             = var.lambda_role_name
  environment           = var.environment
  service_name          = var.service_name
  dynamodb_table_arn    = module.dynamodb.table_arn
  log_group_arns        = values(module.logging.log_group_arns)
  artifact_bucket_arn   = module.artifact_bucket.bucket_arn
  additional_statements = var.lambda_additional_statements
  tags                  = merge(local.base_tags, var.additional_tags)
}

module "iam_event_lambda_role" {
  source                = "../../modules/iam_lambda_role"
  role_name             = var.event_lambda_role_name
  environment           = var.environment
  service_name          = "${var.service_name}-events"
  dynamodb_table_arn    = module.dynamodb.table_arn
  log_group_arns        = values(module.logging.log_group_arns)
  artifact_bucket_arn   = module.artifact_bucket.bucket_arn
  additional_statements = var.lambda_additional_statements
  tags                  = merge(local.base_tags, var.additional_tags)
}

module "lambda_function" {
  source                = "../../modules/lambda_function"
  function_name         = var.lambda_function_name
  description           = var.lambda_description
  role_arn              = module.iam_lambda_role.role_arn
  artifact_bucket_name  = module.artifact_bucket.bucket_id
  artifact_prefix       = var.lambda_artifact_prefix
  source_dir            = abspath(var.lambda_source_dir)
  memory_size           = var.lambda_memory_size
  timeout               = var.lambda_timeout
  environment_variables = local.lambda_env
  tags                  = merge(local.base_tags, var.additional_tags)
}

module "event_lambda" {
  source                = "../../modules/lambda_function"
  function_name         = var.event_lambda_function_name
  description           = var.event_lambda_description
  role_arn              = module.iam_event_lambda_role.role_arn
  artifact_bucket_name  = module.artifact_bucket.bucket_id
  artifact_prefix       = var.event_lambda_artifact_prefix
  source_dir            = abspath(var.event_lambda_source_dir)
  memory_size           = var.event_lambda_memory_size
  timeout               = var.event_lambda_timeout
  environment_variables = local.event_lambda_env
  tags                  = merge(local.base_tags, var.additional_tags)
}

module "api_gateway" {
  source               = "../../modules/api_gateway"
  name                 = var.api_name
  description          = "Serverless REST API for item management"
  lambda_invoke_arn    = module.lambda_function.invoke_arn
  lambda_function_arn  = module.lambda_function.function_arn
  stage_name           = local.api_stage
  cors_allowed_origins = var.cors_allowed_origins
  cors_allowed_headers = var.cors_allowed_headers
  cors_allowed_methods = var.cors_allowed_methods
  tags                 = merge(local.base_tags, var.additional_tags)
}

module "event_dlq" {
  source = "../../modules/sqs_queue"
  name   = var.event_dlq_queue_name
  tags   = merge(local.base_tags, var.additional_tags)
}

module "eventbridge_rule" {
  source                = "../../modules/eventbridge_rule"
  name                  = "${var.service_name}-${var.environment}-schedule"
  description           = "Scheduled background processing"
  schedule_expression   = var.event_lambda_schedule_expression
  target_arn            = module.event_lambda.function_arn
  dead_letter_queue_arn = module.event_dlq.queue_arn
  tags                  = merge(local.base_tags, var.additional_tags)
}

module "monitoring" {
  source                    = "../../modules/monitoring"
  environment               = var.environment
  service_name              = var.service_name
  lambda_function_name      = module.lambda_function.function_name
  api_gateway_id            = module.api_gateway.rest_api_id
  api_stage_name            = local.api_stage
  dynamodb_table_name       = module.dynamodb.table_name
  alarm_actions             = var.monitoring_alarm_actions
  lambda_latency_threshold  = var.lambda_latency_threshold
  lambda_error_threshold    = var.lambda_error_threshold
  lambda_throttle_threshold = var.lambda_throttle_threshold
  dlq_queue_name            = module.event_dlq.queue_name
  tags                      = merge(local.base_tags, var.additional_tags)
}
