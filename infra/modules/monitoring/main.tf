locals {
  alarm_common = {
    alarm_actions             = var.alarm_actions
    ok_actions                = var.alarm_actions
    evaluation_periods        = 1
    insufficient_data_actions = []
    treat_missing_data        = "notBreaching"
    tags                      = var.tags
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.service_name}-${var.environment}-lambda-errors"
  alarm_description   = "Triggers when the Lambda function reports errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.lambda_error_threshold
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions             = local.alarm_common.alarm_actions
  ok_actions                = local.alarm_common.ok_actions
  insufficient_data_actions = local.alarm_common.insufficient_data_actions
  evaluation_periods        = local.alarm_common.evaluation_periods
  treat_missing_data        = local.alarm_common.treat_missing_data
  tags                      = local.alarm_common.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_latency" {
  alarm_name          = "${var.service_name}-${var.environment}-lambda-latency"
  alarm_description   = "Triggers when p95 duration exceeds threshold (ms)."
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.lambda_latency_threshold
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p95"
  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions             = local.alarm_common.alarm_actions
  ok_actions                = local.alarm_common.ok_actions
  insufficient_data_actions = local.alarm_common.insufficient_data_actions
  evaluation_periods        = local.alarm_common.evaluation_periods
  treat_missing_data        = local.alarm_common.treat_missing_data
  tags                      = local.alarm_common.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.service_name}-${var.environment}-lambda-throttles"
  alarm_description   = "Triggers when the Lambda function is throttled."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.lambda_throttle_threshold
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions             = local.alarm_common.alarm_actions
  ok_actions                = local.alarm_common.ok_actions
  insufficient_data_actions = local.alarm_common.insufficient_data_actions
  evaluation_periods        = local.alarm_common.evaluation_periods
  treat_missing_data        = local.alarm_common.treat_missing_data
  tags                      = local.alarm_common.tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttled" {
  alarm_name          = "${var.service_name}-${var.environment}-dynamodb-throttled"
  alarm_description   = "Triggers when DynamoDB throttled requests are detected."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  dimensions = {
    TableName = var.dynamodb_table_name
  }

  alarm_actions             = local.alarm_common.alarm_actions
  ok_actions                = local.alarm_common.ok_actions
  insufficient_data_actions = local.alarm_common.insufficient_data_actions
  evaluation_periods        = local.alarm_common.evaluation_periods
  treat_missing_data        = local.alarm_common.treat_missing_data
  tags                      = local.alarm_common.tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_system_errors" {
  alarm_name          = "${var.service_name}-${var.environment}-dynamodb-system-errors"
  alarm_description   = "Triggers when DynamoDB system errors occur."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  dimensions = {
    TableName = var.dynamodb_table_name
  }

  alarm_actions             = local.alarm_common.alarm_actions
  ok_actions                = local.alarm_common.ok_actions
  insufficient_data_actions = local.alarm_common.insufficient_data_actions
  evaluation_periods        = local.alarm_common.evaluation_periods
  treat_missing_data        = local.alarm_common.treat_missing_data
  tags                      = local.alarm_common.tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_backlog" {
  count               = var.dlq_queue_name == null ? 0 : 1
  alarm_name          = "${var.service_name}-${var.environment}-dlq-backlog"
  alarm_description   = "Triggers when DLQ messages are visible."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  dimensions = {
    QueueName = var.dlq_queue_name
  }

  alarm_actions             = local.alarm_common.alarm_actions
  ok_actions                = local.alarm_common.ok_actions
  insufficient_data_actions = local.alarm_common.insufficient_data_actions
  evaluation_periods        = local.alarm_common.evaluation_periods
  treat_missing_data        = local.alarm_common.treat_missing_data
  tags                      = local.alarm_common.tags
}

locals {
  dashboard_widgets = [
    {
      type   = "metric"
      width  = 24
      height = 6
      properties = {
        title  = "Lambda Performance"
        view   = "timeSeries"
        region = "${data.aws_region.current.name}"
        metrics = [
          ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name],
          [".", "Errors", ".", ".", { "yAxis" : "right" }],
          [".", "Duration", ".", ".", { "stat" : "p95" }]
        ]
        yAxis = {
          left  = { label = "Count" }
          right = { label = "Errors" }
        }
      }
    },
    {
      type   = "metric"
      width  = 24
      height = 6
      properties = {
        title  = "API Gateway Health"
        view   = "timeSeries"
        region = "${data.aws_region.current.name}"
        metrics = [
          ["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id, "Stage", var.api_stage_name],
          [".", "5XXError", ".", ".", { "yAxis" : "right" }],
          [".", "4XXError", ".", ".", { "yAxis" : "right" }],
          [".", "Latency", ".", ".", { "stat" : "p95" }]
        ]
      }
    },
    {
      type   = "metric"
      width  = 24
      height = 6
      properties = {
        title  = "DynamoDB Throughput"
        view   = "timeSeries"
        region = "${data.aws_region.current.name}"
        metrics = [
          ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", var.dynamodb_table_name, { "stat" : "p90" }],
          [".", "ConsumedReadCapacityUnits", ".", "."],
          [".", "ConsumedWriteCapacityUnits", ".", "."]
        ]
      }
    }
  ]
}

data "aws_region" "current" {}

resource "aws_cloudwatch_dashboard" "service" {
  dashboard_name = "${var.service_name}-${var.environment}-dashboard"
  dashboard_body = jsonencode({
    widgets = local.dashboard_widgets
  })
}
