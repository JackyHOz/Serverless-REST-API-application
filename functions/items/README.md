# Items Lambda Functions

This package implements the Lambda entry point backing the REST API. The handler processes all CRUD operations for `/items` and `/items/{id}` using API Gateway's Lambda proxy integration.

## Implementation Notes

* **Node.js 22 + ES Modules** – The runtime targets `nodejs22.x` and uses native ES modules with top-level `import` statements.
* **AWS SDK v3** – The handler bootstraps a `DynamoDBClient` from `@aws-sdk/client-dynamodb` so real table calls can be plugged in without touching infrastructure code.
* **Routing & Validation** – The entry point inspects the HTTP method and resource path to dispatch to create/list/get/update/delete controllers. Each controller validates inputs before proceeding and returns descriptive 400 responses on invalid payloads.
* **Structured Logging** – Logs are emitted as single-line JSON with correlation identifiers, which makes CloudWatch Logs Insights queries straightforward.
* **Configurable Verbosity** – Set `LOG_LEVEL` (debug/info/warn/error) via Terraform to control log volume per environment.
* **Error Handling** – All failures bubble through a centralized `try/catch` path that returns sanitized error messages and status codes while logging contextual metadata for operators.
* **Extensibility** – Replace the placeholder repository interactions with DynamoDB commands (e.g., `PutItemCommand`) by using the provided `dynamoClient`. The environment variable `TABLE_NAME` is injected by Terraform so the function knows which table to target per environment.

## Local Testing

Run `npm install` inside `functions/items`, then execute `node index.mjs` with sample events or use any Lambda testing harness that loads ES module handlers (e.g., `aws-lambda-ric`).
