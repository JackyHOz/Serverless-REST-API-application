import { DynamoDBClient } from "@aws-sdk/client-dynamodb";

const dynamoClient = new DynamoDBClient({});
const allowedOrigins = process.env.CORS_ALLOWED_ORIGINS ?? "*";
const serviceName = process.env.SERVICE_NAME ?? "items-service";
const environmentName = process.env.ENVIRONMENT ?? "dev";
const functionName = process.env.AWS_LAMBDA_FUNCTION_NAME ?? "items-handler";
const awsRegion = process.env.AWS_REGION;
const logLevel = (process.env.LOG_LEVEL ?? "info").toLowerCase();
const levelPriority = { debug: 10, info: 20, warn: 30, error: 40 };
const minPriority = levelPriority[logLevel] ?? levelPriority.info;

const defaultHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": allowedOrigins,
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
};

const log = (level, message, context = {}) => {
  const priority = levelPriority[level] ?? levelPriority.error;
  if (priority < minPriority) {
    return;
  }

  const payload = {
    level,
    message,
    timestamp: new Date().toISOString(),
    service: serviceName,
    environment: environmentName,
    functionName,
    region: awsRegion,
    ...context,
  };

  console.log(JSON.stringify(payload));
};

const jsonResponse = (statusCode, body) => {
  const payload = body === undefined ? "" : JSON.stringify(body);
  return {
    statusCode,
    headers: defaultHeaders,
    body: payload,
  };
};

const parseBody = (rawBody) => {
  if (!rawBody) {
    return {};
  }

  try {
    return JSON.parse(rawBody);
  } catch (error) {
    throw createHttpError(400, "Invalid JSON payload", error);
  }
};

const createHttpError = (statusCode, message, error = null) => {
  const err = new Error(message);
  err.statusCode = statusCode;
  if (error) {
    err.cause = error;
  }

  return err;
};

const ensureString = (value, fieldName, min = 1, max = 256) => {
  if (typeof value !== "string" || value.length < min || value.length > max) {
    throw createHttpError(
      400,
      `${fieldName} must be a string with length between ${min} and ${max}`,
    );
  }

  return value;
};

const normalizePath = (event) => {
  if (event.resource && event.resource !== "/{proxy+}") {
    return event.resource;
  }

  const proxyPath = event.pathParameters?.proxy;
  if (proxyPath) {
    return `/${proxyPath}`;
  }

  return "/";
};

const handleCreateItem = (event) => {
  const payload = parseBody(event.body);
  const id = ensureString(payload.id, "id", 1, 64);
  const name = ensureString(payload.name, "name", 1, 128);
  const description = payload.description ? ensureString(payload.description, "description", 1, 512) : undefined;

  // Placeholder response to demonstrate validation and logging without mutating DynamoDB.
  return jsonResponse(201, {
    message: "Item created (simulation)",
    item: {
      id,
      name,
      description,
    },
  });
};

const handleListItems = () =>
  jsonResponse(200, {
    message: "Listing items (simulation)",
    items: [],
  });

const handleGetItem = (id) => {
  ensureString(id, "id");
  return jsonResponse(200, {
    message: "Get item (simulation)",
    item: { id },
  });
};

const handleUpdateItem = (event, id) => {
  const payload = parseBody(event.body);
  ensureString(id, "id");

  if (!payload.name && !payload.description) {
    throw createHttpError(400, "Provide name or description to update");
  }

  const updates = {};
  if (payload.name) {
    updates.name = ensureString(payload.name, "name", 1, 128);
  }
  if (payload.description) {
    updates.description = ensureString(payload.description, "description", 1, 512);
  }

  return jsonResponse(200, {
    message: "Item updated (simulation)",
    item: { id, ...updates },
  });
};

const handleDeleteItem = (id) => {
  ensureString(id, "id");
  return jsonResponse(204);
};

const routeRequest = (event) => {
  const path = normalizePath(event);
  const method = event.httpMethod?.toUpperCase();

  if (method === "POST" && path === "/items") {
    return handleCreateItem(event);
  }

  if (method === "GET" && path === "/items") {
    return handleListItems();
  }

  const match = path.match(/^\/items\/?([^\/]*)$/);
  if (match && match[1]) {
    const itemId = decodeURIComponent(match[1]);

    if (method === "GET") {
      return handleGetItem(itemId);
    }

    if (method === "PUT") {
      return handleUpdateItem(event, itemId);
    }

    if (method === "DELETE") {
      return handleDeleteItem(itemId);
    }
  }

  throw createHttpError(404, "Route not found");
};

export const handler = async (event, context) => {
  const requestId = event?.requestContext?.requestId ?? context?.awsRequestId;
  const normalizedPath = normalizePath(event);
  log("info", "Received request", { requestId, method: event.httpMethod, path: normalizedPath });

  try {
    const response = routeRequest(event);
    log("info", "Request processed", { requestId, statusCode: response.statusCode ?? 200 });
    return response;
  } catch (error) {
    const statusCode = error.statusCode ?? 500;
    log("error", "Request failed", {
      requestId,
      statusCode,
      message: error.message,
      stack: error.stack,
    });

    return jsonResponse(statusCode, {
      error: statusCode === 500 ? "Internal server error" : error.message,
    });
  }
};

export const dependencies = {
  dynamoClient,
};
