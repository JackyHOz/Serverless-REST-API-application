# Event-Driven Processing

The platform includes a scheduled EventBridge rule that triggers the `event-processor` Lambda to perform maintenance tasks (cache refreshes, aggregations, reporting).

## Flow

1. **EventBridge Schedule** – A cron/rate expression emits events at the configured cadence.
2. **Lambda Invocation** – The `event-processor` Lambda receives the event. Optional `detail.tasks` payloads allow dynamic task lists; otherwise the function executes its default maintenance workflow.
3. **DynamoDB Heartbeat** – After processing, the Lambda updates a configurable item in the shared DynamoDB table with status, timestamp, and metrics, enabling operators to confirm successful runs.
4. **Dead-Letter Queue** – If EventBridge cannot deliver events to Lambda after exhausting retries, the event is sent to the SQS DLQ. CloudWatch alarms (via the monitoring module) alert on any visible DLQ messages.
5. **Monitoring** – Structured JSON logging plus dashboard widgets and alarms (Lambda duration/errors/throttles, DynamoDB health, DLQ depth) provide rapid feedback when a run fails.

## Error Handling

* EventBridge retries failed invocations with exponential backoff for up to 24 hours. A DLQ (SQS) captures events that still fail, preserving context for replay.
* The Lambda updates the heartbeat record with `FAILED` status when its own logic throws, so dashboards immediately reflect the issue.
* Monitoring alarms fan into the configured `monitoring_alarm_actions` target, ensuring responders know when the scheduled job is unhealthy.

## Operations Tips

* To reprocess a failed event, replay the message from the DLQ back into the EventBridge bus or invoke the Lambda manually with the captured payload.
* Customize the `detail.tasks` payload (e.g., via a one-off EventBridge `PutEvents` call) to trigger ad-hoc background jobs using the same Lambda.
