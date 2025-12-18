# Event Processor Lambda

This Lambda handles scheduled EventBridge invocations to perform background maintenance tasks. It writes a heartbeat record to DynamoDB so operators can verify the last successful run.

## Implementation Highlights

* **Node.js 22 ES Modules** – Uses modern syntax alongside the AWS SDK v3 `DynamoDBClient` and `UpdateItemCommand`.
* **Structured Logging** – Emits JSON logs with service, environment, and AWS metadata. The `LOG_LEVEL` env var controls verbosity.
* **Event Awareness** – Accepts arbitrary EventBridge `detail.tasks` payloads but defaults to a synthetic maintenance task when none is provided.
* **DynamoDB Integration** – Updates a heartbeat item (partition/sort key values driven via environment variables) with timestamps and job metrics after each run. Failures also write status updates for auditability.

## Local Testing

```bash
cd functions/event-processor
npm install
npm run build
node index.mjs  # or aws-lambda-ric for invocation simulation
```
