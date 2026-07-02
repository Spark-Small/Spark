/**
 * Staging text moderation (MODULE-E P4).
 * Strategy: post-publish + report queue; block obvious violations at write time.
 * Keep blocked tokens in sync with SparkCore UGCModeration.swift.
 */

const DEFAULT_BLOCKED = [
  "违禁",
  "赌博",
  "色情",
  "刷单",
  "引流微信",
  "加微信",
  "代办证件",
];

function moderationDisabled() {
  const raw = (process.env.MODERATION_DISABLED || "").trim().toLowerCase();
  return raw === "1" || raw === "true" || raw === "yes";
}

function blockedTokens() {
  const raw = (process.env.MODERATION_BLOCKED_TOKENS || "").trim();
  if (!raw) return DEFAULT_BLOCKED;
  return raw.split(",").map((token) => token.trim()).filter(Boolean);
}

function findViolation(text) {
  const normalized = String(text || "").trim().toLowerCase();
  if (!normalized) return null;
  for (const token of blockedTokens()) {
    if (normalized.includes(token.toLowerCase())) {
      return token;
    }
  }
  return null;
}

function moderateFields(fields) {
  if (moderationDisabled()) {
    return { ok: true };
  }
  for (const [name, value] of Object.entries(fields)) {
    const matched = findViolation(value);
    if (matched) {
      return {
        ok: false,
        code: "content_rejected",
        message: `Content violates community guidelines (${name})`,
        matched,
      };
    }
  }
  return { ok: true };
}

module.exports = {
  moderateFields,
  findViolation,
  moderationDisabled,
};
