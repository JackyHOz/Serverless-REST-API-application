# Monitoring & Observability Strategy

This stack provisions CloudWatch dashboards, alarms, and structured logging so operators can detect and diagnose production issues quickly.

## Metric & Alert Coverage

| Component | Metric | Threshold | Rationale |
| --- | --- | --- | --- |
| Lambda | `Errors` (Sum, 1 min) | ≥ 1 | Any error indicates a failed invocation; alerting on the first occurrence keeps MTTR low. |
| Lambda | `Duration` (p95, 5 min) | ≥ 1000 ms | Sustained latency over ~1s signals downstream pressure (DynamoDB, cold starts) and degrades API UX. |
| Lambda | `Throttles` (Sum, 1 min) | ≥ 1 | Throttling means throughput exceeded concurrency limits; alerts allow scaling/concurrency tuning. |
| DynamoDB | `ThrottledRequests` (Sum, 5 min) | ≥ 1 | Indicates adaptive capacity cannot keep up; investigate hot partitions/access patterns. |
| DynamoDB | `SystemErrors` (Sum, 5 min) | ≥ 1 | Surfaces AWS-side issues independent of request volume. |
| API Gateway | `Count`, `Latency` (p95), `4XX/5XXError` | Dashboard visualization | Lets teams correlate traffic spikes and downstream latency with client- or server-side failures. |

Alarm actions are configurable via `monitoring_alarm_actions` so environments can wire SNS topics, PagerDuty, or Slack without editing module code. `treat_missing_data = notBreaching` prevents noise during deployments or scale-to-zero periods.

## Dashboards

The `service-environment-dashboard` dashboard contains three widgets:

1. **Lambda Performance** – Invocations, errors, and p95 duration share a timeline to correlate spikes with latency.
2. **API Gateway Health** – Requests, 4XX/5XX, and p95 latency per stage highlight client vs server issues.
3. **DynamoDB Throughput** – Successful request latency and consumed read/write capacity show when DynamoDB is the bottleneck.

## Structured Logging

Lambda handlers emit single-line JSON with `level`, `service`, `environment`, `functionName`, and AWS region metadata. The `LOG_LEVEL` env var controls verbosity (default `info`). This format feeds CloudWatch Logs Insights so operators can query by level, request ID, or custom context fields without parsing free-form strings.

## CloudWatch Logs Insights Queries

Use the following snippets against the Lambda log group (`/aws/lambda/<function>`):

### Recent Errors by Route

```sql
fields @timestamp, level, message, requestId
| filter level = "error"
| stats count() by path = coalesce(path, "unknown")
| sort count() desc
```

### High-Latency Requests

```sql
fields @timestamp, method, path, statusCode
| filter level = "info" and statusCode >= 500 or message like /latency/
| sort @timestamp desc
| limit 50
```

### Request Timeline for a Correlation ID

```sql
fields @timestamp, level, message
| filter requestId = 'REPLACE_WITH_ID'
| sort @timestamp asc
```

Update the logging context within the Lambda when you add new correlation identifiers (e.g., userId, itemId) so these queries become even more powerful.

## Operations Playbook

1. **Alarm fires** – Investigate the dashboard first to see whether Lambda, API Gateway, or DynamoDB metrics deviated.
2. **Drill into logs** – Use Logs Insights queries above with the request ID from the alarm or API client logs.
3. **Remediation** – Adjust Lambda concurrency/config, provisioned throughput (if applicable), or fix application bugs. Document learnings back into runbooks.
