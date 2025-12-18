# Serverless REST API Infrastructure

This repository demonstrates a production-ready Terraform layout for provisioning the core infrastructure that supports a serverless REST API on AWS. The design emphasizes separation of concerns, repeatable deployments, and clear documentation so that teams can collaborate confidently.

## Architecture Overview

The platform uses versioned S3 buckets to store Lambda deployment packages, a DynamoDB table for request/response data, CloudWatch log groups for structured logging, and least-privilege IAM roles for Node.js 22 Lambda functions. A Mermaid diagram describing the relationships among these components is available at [`docs/architecture.md`](docs/architecture.md).

## Project Structure

```
.
├── docs/
│   └── architecture.md       # Diagram + narrative of the infrastructure
├── functions/
│   ├── event-processor/      # EventBridge-driven Lambda
│   └── items/                # Node.js 22 Lambda source + docs
├── infra/
│   ├── envs/
│   │   └── dev/              # Example environment instantiation
│   │       ├── main.tf       # Composes modules for the environment
│   │       ├── outputs.tf    # Exposes resource identifiers
│   │       ├── variables.tf  # Inputs with validation and descriptions
│   │       └── versions.tf   # Provider + backend configuration
│   └── modules/
│       ├── api_gateway/      # Regional API Gateway REST API with proxy integration
│       ├── artifact_bucket/  # S3 bucket for Lambda artifacts
│       ├── dynamodb_table/   # Encrypted DynamoDB table module
│       ├── iam_lambda_role/  # Lambda execution IAM role
│       ├── lambda_function/  # Packages and deploys Lambda code from source
│       └── logging/          # CloudWatch log groups
└── README.md
```

* `modules/` contains small, composable building blocks that can be reused across environments.
* `envs/<env>/` stitches modules together for each stage (dev, staging, prod), making environment promotion a Terraform variable exercise instead of copy/pasting code.
* `functions/items` holds the Node.js 22 Lambda handlers plus documentation so application developers can evolve the API without touching infrastructure code.
* `functions/event-processor` implements the scheduled EventBridge Lambda responsible for background jobs and DynamoDB heartbeats.
* Documentation lives under `docs/` with diagrams that communicate how the system works for new contributors and reviewers.

## Continuous Integration

GitHub Actions (`.github/workflows/ci.yml`) run on every push/PR to keep the project shippable:

* Terraform validation enforces formatting, initializes modules without a backend, and runs `terraform validate`.
* Lambda validation sets up Node.js 22, installs dependencies, type-checks via `node --check`, and packages the code to mimic deployment.
* tfsec + Checkov scan the Terraform tree for security misconfigurations with no AWS credentials required.
* Markdown linting keeps documentation readable.

Details on the workflow design and how to reproduce the steps locally are documented in [`docs/cicd.md`](docs/cicd.md).

The workflow targets a self-hosted runner so teams can access internal dependencies (private registries, shared build caches, or corporate network tooling) while keeping the same validation surface as GitHub-hosted runners.

## Monitoring & Alerting

Terraform provisions CloudWatch dashboards and alarms covering Lambda errors/latency/throttles, API Gateway traffic/latency, and DynamoDB throttling/system errors. Alarm actions are configurable per environment via `monitoring_alarm_actions`, and dashboards visualize service health at a glance. Structured JSON logging in the Lambda handler makes CloudWatch Logs Insights queries trivial; see [`docs/monitoring.md`](docs/monitoring.md) for metric rationale, thresholds, and troubleshooting queries.

## Event-Driven Processing

A scheduled EventBridge rule invokes the `event-processor` Lambda for recurring maintenance tasks. Events that still fail after retries land in an encrypted SQS DLQ, which is also monitored for backlog. The Lambda records a heartbeat item in DynamoDB so ops teams can confirm the last successful run. The full flow, error-handling guarantees, and replay tips are documented in [`docs/events.md`](docs/events.md), and the system diagram in [`docs/architecture.md`](docs/architecture.md) illustrates how the DLQ and schedule tie into the broader platform.

## Architectural Decisions

1. **Module-per-concern** – Every AWS component (artifact bucket, DynamoDB, Lambda, IAM, API Gateway, logging, monitoring, EventBridge, SQS) lives in its own Terraform module. This keeps surface areas small, enables reuse across environments, and makes future services (e.g., staging/prod) a matter of wiring modules together instead of copying monolith TF files.
2. **DynamoDB as single source of truth** – Both synchronous API calls and background jobs hit the same encrypted table with point-in-time recovery. This minimizes operational overhead and ensures scheduled tasks can piggyback on the same schema for heartbeats/metrics without additional storage.
3. **S3 artifact bucket + inline packaging** – Terraform’s `archive_file` plus a dedicated artifact bucket removes the need for separate build pipelines during prototyping while still following IaC best practices. Teams can later replace the packaging step with CI uploads without touching the module interface.
4. **Structured logging everywhere** – Both Lambdas share a consistent JSON logging contract with log-level gating. This decision enables CloudWatch Logs Insights queries, simplifies incident investigation, and keeps logs analytics-ready for downstream tooling (e.g., OpenSearch).
5. **Defense-in-depth monitoring** – Dashboards aggregate Lambda/API/DynamoDB/SQS metrics, while alarms cover errors, latency, throttles, and DLQ backlog. The monitoring module takes alarm action ARNs as inputs so organizations can plug in their preferred alerting stack (SNS/PagerDuty/Slack) per environment.
6. **EventBridge-first background jobs** – Instead of cron-like Lambda invocations, EventBridge drives schedules with DLQ + retry semantics and supports dynamic payloads. This pattern scales to future event-driven features (publishing domain events, fan-out processing) without changing the Lambda code.

## Lambda Implementation

`functions/items` exposes a consolidated Lambda handler that routes CRUD operations for `/items` and `/items/{id}`. Highlights:

* ES Module syntax targeting the Node.js 22 runtime with modular AWS SDK v3 imports.
* Structured JSON logging and consistent error handling to aid observability in CloudWatch Logs.
* Strict input validation so malformed requests short-circuit with descriptive `4xx` responses.
* Environment-driven configuration (`TABLE_NAME`, `CORS_ALLOWED_ORIGINS`, etc.) injected by Terraform for each stage.

## Terraform Workflow

1. Configure backend state for each environment (e.g., `terraform init -backend-config="bucket=..." -backend-config="key=dev/terraform.tfstate"`).
2. Provide the required variables using a `.tfvars` file or environment variables. A sample variable set:

```hcl
aws_region                = "us-east-1"
environment               = "dev"
service_name              = "serverless-api"
artifact_bucket_name      = "dev-serverless-api-artifacts"
dynamodb_table_name       = "dev-serverless-api"
dynamodb_hash_key         = "pk"
dynamodb_range_key        = "sk"
log_group_names           = [
  "/aws/lambda/serverless-api-dev-rest",
  "/aws/lambda/serverless-api-dev-schedule",
]
log_retention_days        = 30
lambda_role_name          = "serverless-api-dev-lambda"
lambda_function_name      = "serverless-api-dev-rest"
lambda_source_dir         = "../../functions/items"
lambda_log_level          = "info"
event_lambda_role_name    = "serverless-api-dev-events-role"
event_lambda_function_name = "serverless-api-dev-schedule"
event_lambda_source_dir   = "../../functions/event-processor"
event_lambda_schedule_expression = "rate(5 minutes)"
event_dlq_queue_name      = "serverless-api-dev-event-dlq"
api_name                  = "serverless-rest-api"
api_stage_name            = "dev"
cors_allowed_origins      = ["https://app.example.com"]
monitoring_alarm_actions  = ["arn:aws:sns:us-east-1:123456789012:alerts"]
lambda_latency_threshold  = 1000
lambda_error_threshold    = 1
lambda_throttle_threshold = 1
additional_tags = {
  Owner = "platform-team"
}
```

> ℹ️ `cors_allowed_origins` should contain a single value (often `"*"` or the frontend origin). The first entry is used for `Access-Control-Allow-Origin`.

3. Run `terraform plan` and `terraform apply` from `infra/envs/dev` (or the target environment directory).

## Local Validation

Before opening a pull request or applying changes, run the same checks that CI executes:

```bash
# Terraform formatting + validation
(cd infra/envs/dev && terraform fmt -recursive && terraform init -backend=false && terraform validate)

# Lambda dependencies and syntax checks
(cd functions/items && npm install && npm run build)
(cd functions/event-processor && npm install && npm run build)

# Infrastructure security scan
(cd infra && checkov -d .)

# Documentation lint
npx markdownlint-cli2 "**/*.md"
```

Packaging (`npm run package`) happens automatically in CI, but you can run it locally to inspect the ZIPs before deploying.

## Security & DevOps Considerations

* **Least privilege IAM** – The Lambda role is limited to DynamoDB CRUD, CloudWatch logging, and read-only access to the artifact bucket. Additional statements can be provided per environment when new integrations are needed.
* **Encryption & versioning** – S3 artifacts enforce versioning and SSE, DynamoDB enables encryption and point-in-time recovery, and CloudWatch logs optionally accept a KMS key.
* **Validation** – Variables include type constraints and regex/enum validation to catch misconfiguration before apply.
* **Extensibility** – Modules now cover the artifact bucket, Lambda packaging, IAM, DynamoDB, logging, and API Gateway so additional environments or integrations simply wire in new instances.
* **Testing** – Terraform code is structured for Terratest or `terraform validate` in CI. 
* **Reminder** – The REST Lambda currently simulates CRUD operations and does not write to DynamoDB. Swap in real SDK commands (`PutItem`, `Query`, etc.) once data contracts are finalized.

## Assumptions & Trade-offs

* **Stubbed CRUD logic** – The REST Lambda currently simulates DynamoDB operations so infrastructure can be verified without mutating data. Swap in real `PutItem/GetItem` calls once data contracts are defined.
* **Single DynamoDB table** – Both the API and scheduled processor share one table for simplicity. Introduce additional tables or secondary indexes as the domain grows.
* **Per-environment tagging** – Tags are merged via locals; if your organization enforces global guardrails, pass them through `additional_tags`.
* **Manual artifact builds** – Terraform zips local folders; CI packages them automatically. In production, consider a dedicated build pipeline that uploads to the artifact bucket instead.
* **Regional deployment** – All modules assume a single AWS region per environment. Multi-region redundancy would require duplicating the env folder or adding additional provider blocks.

