locals {
  cors_origin_header  = var.cors_allowed_origins[0]
  cors_headers_header = join(",", var.cors_allowed_headers)
  cors_methods_header = join(",", var.cors_allowed_methods)
  cors_response_params = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_rest_api" "this" {
  name        = var.name
  description = var.description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

# Lambda proxy for the root resource
resource "aws_api_gateway_method" "root_any" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_rest_api.this.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_any" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_rest_api.this.root_resource_id
  http_method             = aws_api_gateway_method.root_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Lambda proxy for /{proxy+}
resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_any" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# OPTIONS for root
resource "aws_api_gateway_method" "root_options" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_rest_api.this.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\n  \"statusCode\": 200\n}"
  }
}

resource "aws_api_gateway_method_response" "root_options" {
  rest_api_id         = aws_api_gateway_rest_api.this.id
  resource_id         = aws_api_gateway_rest_api.this.root_resource_id
  http_method         = aws_api_gateway_method.root_options.http_method
  status_code         = "200"
  response_parameters = local.cors_response_params
}

resource "aws_api_gateway_integration_response" "root_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  status_code = aws_api_gateway_method_response.root_options.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${local.cors_headers_header}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${local.cors_methods_header}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${local.cors_origin_header}'"
  }
}

# OPTIONS for /{proxy+}
resource "aws_api_gateway_method" "proxy_options" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\n  \"statusCode\": 200\n}"
  }
}

resource "aws_api_gateway_method_response" "proxy_options" {
  rest_api_id         = aws_api_gateway_rest_api.this.id
  resource_id         = aws_api_gateway_resource.proxy.id
  http_method         = aws_api_gateway_method.proxy_options.http_method
  status_code         = "200"
  response_parameters = local.cors_response_params
}

resource "aws_api_gateway_integration_response" "proxy_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  status_code = aws_api_gateway_method_response.proxy_options.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${local.cors_headers_header}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${local.cors_methods_header}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${local.cors_origin_header}'"
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_method.root_any.id,
      aws_api_gateway_method.proxy_options.id,
      aws_api_gateway_method.root_options.id,
      var.lambda_invoke_arn,
      var.cors_allowed_origins,
      var.cors_allowed_headers,
      var.cors_allowed_methods,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.proxy_any,
    aws_api_gateway_integration.root_any,
    aws_api_gateway_integration.proxy_options,
    aws_api_gateway_integration.root_options,
  ]
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.this.id
  tags          = var.tags
}

resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  response_type = "DEFAULT_4XX"
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${local.cors_origin_header}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'${local.cors_headers_header}'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'${local.cors_methods_header}'"
  }
}

resource "aws_api_gateway_gateway_response" "default_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  response_type = "DEFAULT_5XX"
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${local.cors_origin_header}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'${local.cors_headers_header}'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'${local.cors_methods_header}'"
  }
}
