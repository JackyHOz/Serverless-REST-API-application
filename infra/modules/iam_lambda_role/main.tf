data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = var.assume_role_services
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = compact([
      var.dynamodb_table_arn,
      var.dynamodb_table_arn != null ? "${var.dynamodb_table_arn}/index/*" : null,
    ])
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = var.log_group_arns
  }

  statement {
    sid    = "ArtifactReadOnly"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = compact([
      var.artifact_bucket_arn,
      var.artifact_bucket_arn != null ? "${var.artifact_bucket_arn}/*" : null,
    ])
  }

  dynamic "statement" {
    for_each = var.additional_statements
    content {
      sid       = lookup(statement.value, "sid", null)
      effect    = lookup(statement.value, "effect", "Allow")
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = merge(
    {
      "Environment" = var.environment
      "Service"     = var.service_name
    },
    var.tags,
  )
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.role_name}-inline"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}
