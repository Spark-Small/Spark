/**
 * CN auth provider verification — WeChat, phone one-tap (Aliyun/Tencent), Alipay.
 * Staging magic tokens work without vendor credentials (docs/STAGING.md).
 */

const crypto = require("crypto");

const STAGING = {
  wechatCode: "staging-wechat-code",
  aliyunToken: "staging-aliyun-token",
  tencentToken: "staging-tencent-token",
  alipayCode: "staging-alipay-code",
  otpCode: "123456",
};

function phoneHash(rawPhone) {
  return crypto.createHash("sha256").update(String(rawPhone)).digest("hex").slice(0, 32);
}

function ensureUsersByProvider(state) {
  if (!state.usersByProvider) {
    state.usersByProvider = new Map();
  }
}

function findUserIdByProvider(state, kind, externalId) {
  ensureUsersByProvider(state);
  const fromIndex = state.usersByProvider.get(`${kind}:${externalId}`);
  if (fromIndex) return fromIndex;

  for (const user of Object.values(state.users)) {
    const providers = user.auth_providers || {};
    if (kind === "wechat" && providers.wechat_union_id === externalId) return user.user_id;
    if (kind === "phone" && providers.phone_hash === externalId) return user.user_id;
    if (kind === "alipay" && providers.alipay_user_id === externalId) return user.user_id;
  }
  return null;
}

function nextAnonymousUserId(state) {
  state.counters.user_counter = (state.counters.user_counter || 100) + 1;
  return `u_cn_${state.counters.user_counter}`;
}

function upsertProviderUser(state, { kind, externalId, displayName }) {
  ensureUsersByProvider(state);
  let userId = findUserIdByProvider(state, kind, externalId);
  if (!userId) {
    userId = nextAnonymousUserId(state);
    state.usersByProvider.set(`${kind}:${externalId}`, userId);
    if (state.dirty) state.dirty.meta = true;
  }

  const providerPatch = {};
  if (kind === "wechat") providerPatch.wechat_union_id = externalId;
  if (kind === "phone") providerPatch.phone_hash = externalId;
  if (kind === "alipay") providerPatch.alipay_user_id = externalId;

  const existingKey = Object.keys(state.users).find((k) => state.users[k].user_id === userId);
  if (existingKey) {
    state.users[existingKey].auth_providers = {
      ...(state.users[existingKey].auth_providers || {}),
      ...providerPatch,
    };
    if (state.dirty) state.dirty.users.add(existingKey);
  } else {
    const syntheticKey = `provider:${kind}:${externalId}`;
    state.users[syntheticKey] = {
      user_id: userId,
      name: displayName || "Spark User",
      auth_providers: providerPatch,
    };
    if (state.dirty) state.dirty.users.add(syntheticKey);
  }

  return userId;
}

async function verifyWeChatCode(code) {
  if (!code || typeof code !== "string") {
    throw providerError("invalid_request", "Missing WeChat code");
  }
  if (code === STAGING.wechatCode) {
    return { unionId: "staging_wechat_union", openId: "staging_wechat_open" };
  }

  const appId = process.env.WECHAT_APP_ID;
  const secret = process.env.WECHAT_APP_SECRET;
  if (!appId || !secret) {
    throw providerError("provider_not_configured", "WeChat auth is not configured on server");
  }

  const url =
    "https://api.weixin.qq.com/sns/oauth2/access_token" +
    `?appid=${encodeURIComponent(appId)}` +
    `&secret=${encodeURIComponent(secret)}` +
    `&code=${encodeURIComponent(code)}` +
    "&grant_type=authorization_code";
  const resp = await fetch(url);
  const data = await resp.json();
  if (data.errcode) {
    throw providerError("invalid_credentials", data.errmsg || "WeChat authorization failed");
  }
  const unionId = data.unionid || data.openid;
  if (!unionId) {
    throw providerError("invalid_credentials", "WeChat did not return an identity");
  }
  return { unionId, openId: data.openid };
}

async function verifyPhoneOneTap(provider, token) {
  if (!token || typeof token !== "string") {
    throw providerError("invalid_request", "Missing phone one-tap token");
  }
  const normalized = String(provider || "").toLowerCase();
  if (normalized !== "aliyun" && normalized !== "tencent") {
    throw providerError("invalid_request", "provider must be aliyun or tencent");
  }

  if (normalized === "aliyun" && token === STAGING.aliyunToken) {
    return { phone: "+8613800138000", provider: "aliyun" };
  }
  if (normalized === "tencent" && token === STAGING.tencentToken) {
    return { phone: "+8613800138001", provider: "tencent" };
  }

  if (normalized === "aliyun") {
    return verifyAliyunPhoneToken(token);
  }
  return verifyTencentPhoneToken(token);
}

function normalizePhone(phone) {
  return String(phone || "").trim();
}

function verifyPhoneOTPCode(phone, code) {
  const normalizedPhone = normalizePhone(phone);
  if (!normalizedPhone) {
    throw providerError("invalid_request", "Missing phone for OTP");
  }
  if (!code || typeof code !== "string") {
    throw providerError("invalid_request", "Missing OTP code");
  }
  if (code !== STAGING.otpCode) {
    throw providerError("invalid_credentials", "Invalid OTP code");
  }
  return normalizedPhone;
}

async function verifyAliyunPhoneToken(token) {
  const accessKeyId = process.env.ALIYUN_PHONE_AUTH_ACCESS_KEY_ID;
  const accessKeySecret = process.env.ALIYUN_PHONE_AUTH_ACCESS_KEY_SECRET;
  if (!accessKeyId || !accessKeySecret) {
    throw providerError("provider_not_configured", "Aliyun phone auth is not configured on server");
  }
  // REASONING: Production uses DYPNS GetMobile; staging uses magic tokens above.
  throw providerError("invalid_credentials", "Aliyun phone token verification failed (configure GetMobile)");
}

async function verifyTencentPhoneToken(token) {
  const secretId = process.env.TENCENT_PHONE_AUTH_SECRET_ID;
  const secretKey = process.env.TENCENT_PHONE_AUTH_SECRET_KEY;
  if (!secretId || !secretKey) {
    throw providerError("provider_not_configured", "Tencent phone auth is not configured on server");
  }
  throw providerError("invalid_credentials", "Tencent phone token verification failed (configure Verify API)");
}

function prepareAlipayAuthInfo() {
  const appId = process.env.ALIPAY_APP_ID;
  if (!appId) {
    throw providerError("provider_not_configured", "Alipay auth is not configured on server");
  }
  const pid = process.env.ALIPAY_PARTNER_ID || appId;
  const targetId = process.env.ALIPAY_TARGET_ID || appId;
  const authInfo = [
    `apiname=com.alipay.account.auth`,
    `method=alipay.open.auth.sdk.code.get`,
    `app_id=${appId}`,
    `app_name=mc`,
    `biz_type=openservice`,
    `pid=${pid}`,
    `product_id=APP_FAST_LOGIN`,
    `scope=kuaijie`,
    `target_id=${targetId}`,
    `auth_type=AUTHACCOUNT`,
    `sign_type=RSA2`,
  ].join("&");
  return { auth_info: authInfo };
}

async function verifyAlipayAuthCode(authCode) {
  if (!authCode || typeof authCode !== "string") {
    throw providerError("invalid_request", "Missing Alipay auth code");
  }
  if (authCode === STAGING.alipayCode) {
    return { alipayUserId: "staging_alipay_user" };
  }

  const appId = process.env.ALIPAY_APP_ID;
  if (!appId) {
    throw providerError("provider_not_configured", "Alipay auth is not configured on server");
  }
  throw providerError(
    "invalid_credentials",
    "Alipay auth code verification failed (configure alipay.system.oauth.token)"
  );
}

function providerError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function registerAuthRoutes(app, { state, tokenFor, err }) {
  app.post("/v1/auth/wechat", async (req, res) => {
    try {
      const { code } = req.body || {};
      const { unionId } = await verifyWeChatCode(code);
      const userId = upsertProviderUser(state, {
        kind: "wechat",
        externalId: unionId,
        displayName: "微信用户",
      });
      res.json({ access_token: tokenFor(userId), user_id: userId });
    } catch (error) {
      mapProviderError(res, err, error);
    }
  });

  app.post("/v1/auth/phone-one-tap", async (req, res) => {
    try {
      const { provider, token } = req.body || {};
      const verified = await verifyPhoneOneTap(provider, token);
      const hash = phoneHash(verified.phone);
      const userId = upsertProviderUser(state, {
        kind: "phone",
        externalId: hash,
        displayName: "手机用户",
      });
      res.json({ access_token: tokenFor(userId), user_id: userId });
    } catch (error) {
      mapProviderError(res, err, error);
    }
  });

  app.post("/v1/auth/phone-otp/send", async (req, res) => {
    try {
      const { phone } = req.body || {};
      const normalizedPhone = normalizePhone(phone);
      if (!normalizedPhone) {
        throw providerError("invalid_request", "Missing phone");
      }
      // REASONING: staging-only OTP — we don't send SMS in MVP.
      res.json({ ok: true });
    } catch (error) {
      mapProviderError(res, err, error);
    }
  });

  app.post("/v1/auth/phone-otp/verify", async (req, res) => {
    try {
      const { phone, code } = req.body || {};
      const normalizedPhone = verifyPhoneOTPCode(phone, code);
      const hash = phoneHash(normalizedPhone);
      const userId = upsertProviderUser(state, {
        kind: "phone",
        externalId: hash,
        displayName: "手机用户",
      });
      res.json({ access_token: tokenFor(userId), user_id: userId });
    } catch (error) {
      mapProviderError(res, err, error);
    }
  });

  app.get("/v1/auth/alipay/prepare", (_req, res) => {
    try {
      res.json(prepareAlipayAuthInfo());
    } catch (error) {
      mapProviderError(res, err, error);
    }
  });

  app.post("/v1/auth/alipay", async (req, res) => {
    try {
      const { auth_code: authCode } = req.body || {};
      const { alipayUserId } = await verifyAlipayAuthCode(authCode);
      const userId = upsertProviderUser(state, {
        kind: "alipay",
        externalId: alipayUserId,
        displayName: "支付宝用户",
      });
      res.json({ access_token: tokenFor(userId), user_id: userId });
    } catch (error) {
      mapProviderError(res, err, error);
    }
  });
}

function mapProviderError(res, err, error) {
  const code = error.code || "invalid_credentials";
  const status = code === "provider_not_configured" ? 503 : code === "invalid_request" ? 400 : 401;
  err(res, status, code, error.message || "Authentication failed");
}

module.exports = {
  STAGING,
  registerAuthRoutes,
  verifyWeChatCode,
  verifyPhoneOneTap,
  prepareAlipayAuthInfo,
  verifyAlipayAuthCode,
  upsertProviderUser,
  phoneHash,
};
