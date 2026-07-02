/**
 * APNs HTTP/2 sender (MODULE-B.3).
 * REASONING: Uses Node crypto + http2 only — no extra deps. When APNS_* env vars
 * are unset, callers should treat push as queued/stub.
 */

const http2 = require("http2");
const crypto = require("crypto");

const SANDBOX_HOST = "api.sandbox.push.apple.com";
const PRODUCTION_HOST = "api.push.apple.com";

function isConfigured() {
  return Boolean(
    process.env.APNS_KEY_ID &&
      process.env.APNS_TEAM_ID &&
      process.env.APNS_PRIVATE_KEY &&
      process.env.APNS_BUNDLE_ID
  );
}

function apnsHost() {
  const useSandbox = process.env.APNS_USE_SANDBOX !== "false";
  return useSandbox ? SANDBOX_HOST : PRODUCTION_HOST;
}

function normalizePrivateKey(raw) {
  if (!raw) return "";
  return raw.includes("\\n") ? raw.replace(/\\n/g, "\n") : raw;
}

let cachedJwt = null;
let cachedJwtIssuedAt = 0;

function apnsJwt() {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJwt && now - cachedJwtIssuedAt < 3000) {
    return cachedJwt;
  }
  const header = Buffer.from(
    JSON.stringify({ alg: "ES256", kid: process.env.APNS_KEY_ID })
  ).toString("base64url");
  const payload = Buffer.from(
    JSON.stringify({ iss: process.env.APNS_TEAM_ID, iat: now })
  ).toString("base64url");
  const signingInput = `${header}.${payload}`;
  const key = normalizePrivateKey(process.env.APNS_PRIVATE_KEY);
  const sign = crypto.createSign("SHA256");
  sign.update(signingInput);
  sign.end();
  const signature = sign.sign({ key, dsaEncoding: "ieee-p1363" }).toString("base64url");
  cachedJwt = `${signingInput}.${signature}`;
  cachedJwtIssuedAt = now;
  return cachedJwt;
}

function buildNotificationBody(type, payload = {}) {
  const data = { type, ...payload };
  switch (type) {
    case "activity.reminder":
    case "activity.cancelled":
    case "activity.updated":
      return {
        aps: {
          alert: {
            title: payload.title || "活动更新",
            body: payload.body || "查看活动详情",
          },
          sound: "default",
        },
        activity_id: payload.activity_id,
        ...data,
      };
    case "community.reply":
      return {
        aps: {
          alert: {
            title: payload.title || "新回复",
            body: payload.body || "有人回复了你的帖子",
          },
          sound: "default",
        },
        post_id: payload.post_id,
        ...data,
      };
    case "community.like":
      return {
        aps: {
          alert: {
            title: payload.title || "新赞",
            body: payload.body || "有人赞了你的帖子",
          },
          sound: "default",
        },
        post_id: payload.post_id,
        ...data,
      };
    case "messages.new":
      return {
        aps: {
          alert: {
            title: payload.title || "新消息",
            body: payload.body || "你收到一条新消息",
          },
          sound: "default",
          badge: 1,
        },
        thread_id: payload.thread_id,
        ...data,
      };
    default:
      return {
        aps: {
          alert: {
            title: payload.title || "Spark",
            body: payload.body || type,
          },
          sound: "default",
        },
        ...data,
      };
  }
}

function sendToDevice(deviceToken, body, { pushType = "alert" } = {}) {
  return new Promise((resolve, reject) => {
    const client = http2.connect(`https://${apnsHost()}`);
    client.on("error", reject);

    const req = client.request({
      ":method": "POST",
      ":path": `/3/device/${deviceToken}`,
      authorization: `bearer ${apnsJwt()}`,
      "apns-topic": process.env.APNS_BUNDLE_ID,
      "apns-push-type": pushType,
      "apns-priority": pushType === "background" ? "5" : "10",
    });

    let responseData = "";
    req.on("response", (headers) => {
      const status = headers[":status"];
      req.on("data", (chunk) => {
        responseData += chunk;
      });
      req.on("end", () => {
        client.close();
        if (status === 200) {
          resolve({ ok: true, status });
        } else {
          reject(new Error(`APNs ${status}: ${responseData || "unknown"}`));
        }
      });
    });
    req.on("error", (error) => {
      client.close();
      reject(error);
    });
    req.end(JSON.stringify(body));
  });
}

function deviceTokensForUser(devicesMap, userId) {
  const tokens = [];
  for (const [token, device] of devicesMap.entries()) {
    if (device.user_id === userId && device.platform !== "android") {
      tokens.push(token);
    }
  }
  return tokens;
}

async function sendPushToUser(devicesMap, userId, type, payload = {}) {
  if (!isConfigured()) {
    return { configured: false, sent: 0, failed: 0, errors: [] };
  }
  const tokens = deviceTokensForUser(devicesMap, userId);
  if (tokens.length === 0) {
    return { configured: true, sent: 0, failed: 0, errors: [], reason: "no_devices" };
  }
  const body = buildNotificationBody(type, payload);
  let sent = 0;
  let failed = 0;
  const errors = [];
  for (const token of tokens) {
    try {
      await sendToDevice(token, body);
      sent += 1;
    } catch (error) {
      failed += 1;
      errors.push({ token: token.slice(0, 8), message: error.message });
    }
  }
  return { configured: true, sent, failed, errors };
}

module.exports = {
  isConfigured,
  buildNotificationBody,
  sendPushToUser,
};
