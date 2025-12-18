import { DynamoDBClient, UpdateItemCommand } from "@aws-sdk/client-dynamodb";

const dynamo = new DynamoDBClient({});
const logLevel = (process.env.LOG_LEVEL ?? "info").toLowerCase();
const levelPriority = { debug: 10, info: 20, warn: 30, error: 40 };
const minPriority = levelPriority[logLevel] ?? levelPriority.info;
const serviceName = process.env.SERVICE_NAME ?? "event-processor";
const environmentName = process.env.ENVIRONMENT ?? "dev";
const functionName = process.env.AWS_LAMBDA_FUNCTION_NAME ?? "event-processor";
const awsRegion = process.env.AWS_REGION;
const tableName = process.env.TABLE_NAME;
const hashKeyName = process.env.TABLE_HASH_KEY ?? "pk";
const rangeKeyName = process.env.TABLE_RANGE_KEY;
const heartbeatPk = process.env.EVENT_PK_VALUE ?? `${serviceName}#maintenance`;
const heartbeatSk = process.env.EVENT_SK_VALUE ?? "scheduled-job";

const log = (level, message, context = {}) => {
  const priority = levelPriority[level] ?? levelPriority.error;
  if (priority < minPriority) {
    return;
  }

  console.log(
    JSON.stringify({
      level,
      message,
      timestamp: new Date().toISOString(),
      service: serviceName,
      environment: environmentName,
      functionName,
      region: awsRegion,
      ...context,
    }),
  );
};

const updateHeartbeat = async (jobId, status, metrics = {}) => {
  if (!tableName) {
    throw new Error("TABLE_NAME environment variable is required");
  }

  const key = {
    [hashKeyName]: { S: heartbeatPk },
  };

  if (rangeKeyName) {
    key[rangeKeyName] = { S: heartbeatSk };
  }

  const command = new UpdateItemCommand({
    TableName: tableName,
    Key: key,
    UpdateExpression: "SET lastRun = :ts, jobStatus = :status, metrics = :metrics, jobId = :jobId",
    ExpressionAttributeValues: {
      ":ts": { S: new Date().toISOString() },
      ":status": { S: status },
      ":metrics": { S: JSON.stringify(metrics) },
      ":jobId": { S: jobId },
    },
  });

  await dynamo.send(command);
};

const extractTasks = (event) => {
  if (Array.isArray(event?.detail?.tasks)) {
    return event.detail.tasks;
  }

  return [
    {
      id: "refresh-cache",
      description: "Default maintenance task",
    },
  ];
};

export const handler = async (event, context) => {
  const requestId = context?.awsRequestId;
  const detailType = event?.detail_type ?? "ScheduledEvent";
  const tasks = extractTasks(event);
  log("info", "Processing scheduled tasks", { requestId, detailType, taskCount: tasks.length });

  try {
    const metrics = {
      tasksScheduled: tasks.length,
      scheduleTime: event?.time,
    };

    await updateHeartbeat(detailType, "SUCCESS", metrics);

    log("info", "Scheduled tasks processed", { requestId, ...metrics });
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Tasks processed", metrics }),
    };
  } catch (error) {
    log("error", "Scheduled tasks failed", {
      requestId,
      message: error.message,
      stack: error.stack,
    });

    if (tableName) {
      await updateHeartbeat(detailType, "FAILED", { error: error.message });
    }

    throw error;
  }
};

export const dependencies = {
  dynamo,
};
