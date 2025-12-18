locals {
  trimmed_prefix    = trim(var.artifact_prefix, "/")
  normalized_prefix = local.trimmed_prefix != "" ? local.trimmed_prefix : "lambda"
}

data "archive_file" "package" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.function_name}.zip"
}

resource "aws_s3_object" "package" {
  bucket       = var.artifact_bucket_name
  key          = "${local.normalized_prefix}/${var.function_name}-${data.archive_file.package.output_base64sha256}.zip"
  source       = data.archive_file.package.output_path
  etag         = data.archive_file.package.output_md5
  tags         = var.tags
  content_type = "application/zip"
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  description      = var.description
  handler          = var.handler
  runtime          = var.runtime
  role             = var.role_arn
  memory_size      = var.memory_size
  timeout          = var.timeout
  architectures    = var.architectures
  publish          = var.publish
  s3_bucket        = aws_s3_object.package.bucket
  s3_key           = aws_s3_object.package.key
  source_code_hash = data.archive_file.package.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}
