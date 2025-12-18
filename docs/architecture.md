# Serverless REST API Infrastructure Architecture

![Serverless REST API Architecture](./Serverless%20REST%20API%20Infrastructure%20Architecture.jpg)

> The editable source lives in [`docs/Serverless REST API Infrastructure Architecture.drawio`](Serverless%20REST%20API%20Infrastructure%20Architecture.drawio); open it with draw.io/diagrams.net to make updates, then export to the JPEG above to keep the Markdown view in sync.

* CI/CD pushes Node.js 22 Lambda deployment packages into an encrypted, versioned S3 bucket for both request/response and background workloads.
* API Gateway exposes HTTPS endpoints with CORS controls, proxying every call to the REST Lambda function.
* A scheduled EventBridge rule invokes the Event Processor Lambda for background jobs; failed deliveries are parked in an SQS dead-letter queue for replay.
* Lambdas assume least-privilege IAM roles that grant DynamoDB CRUD, artifact read access, and structured logging permissions.
* Application data is persisted in an encrypted DynamoDB table with point-in-time recovery.
* CloudWatch log groups retain structured logs for diagnostics and security reviews.
