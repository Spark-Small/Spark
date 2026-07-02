/**
 * Staging phone OTP store — TTL, resend cooldown, one-time verify.
 * Production replaces console.log with SMS provider; contract: docs/API_CONTRACT.md
 */

const OTP_TTL_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const OTP_CODE_LENGTH = 6;

function isValidCNMobilePhone(phone) {
  return typeof phone === "string" && /^1\d{10}$/.test(phone);
}

function sendPhoneOTP(state, phone) {
  if (!isValidCNMobilePhone(phone)) {
    return { status: 400, code: "invalid_request", message: "Valid phone required" };
  }
  const now = Date.now();
  const existing = state.phoneOtps.get(phone);
  if (existing && now - existing.lastSentAt < RESEND_COOLDOWN_MS) {
    return { status: 429, code: "too_many_requests", message: "Resend too soon" };
  }
  const code = String(Math.floor(100000 + Math.random() * 900000));
  state.phoneOtps.set(phone, {
    code,
    expiresAt: now + OTP_TTL_MS,
    lastSentAt: now,
  });
  // REASONING: Staging-only OTP log for manual testing; never emit in production.
  if (process.env.NODE_ENV !== "production") {
    console.log(`[spark-api][staging-otp] phone=${phone} code=${code}`);
  }
  return { status: 204 };
}

function verifyPhoneOTP(state, phone, code) {
  const entry = state.phoneOtps.get(phone);
  if (!entry) return false;
  if (Date.now() > entry.expiresAt) {
    state.phoneOtps.delete(phone);
    return false;
  }
  if (entry.code !== String(code)) return false;
  state.phoneOtps.delete(phone);
  return true;
}

function ensurePhoneUser(state, phone) {
  let user = state.phoneUsers.get(phone);
  if (!user) {
    user = {
      user_id: `phone_${phone}`,
      phone,
      password: null,
      name: "手机用户",
    };
    state.phoneUsers.set(phone, user);
  }
  return user;
}

function setPhoneUserPassword(state, phone, newPassword) {
  const user = ensurePhoneUser(state, phone);
  user.password = newPassword;
  state.phoneUsers.set(phone, user);
  return user;
}

function purgePhoneAccount(state, userId) {
  for (const [phone, user] of state.phoneUsers.entries()) {
    if (user.user_id === userId) {
      state.phoneUsers.delete(phone);
      state.phoneOtps.delete(phone);
    }
  }
}

module.exports = {
  OTP_CODE_LENGTH,
  isValidCNMobilePhone,
  sendPhoneOTP,
  verifyPhoneOTP,
  ensurePhoneUser,
  setPhoneUserPassword,
  purgePhoneAccount,
};
