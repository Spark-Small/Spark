/**
 * CN payment orders — WeChat Pay and Alipay (staging magic receipts).
 * REASONING: Digital premium on global App Store remains StoreKit; CN paths are feature-flagged.
 */

const STAGING_PAYMENTS = {
  wechatReceipt: "staging-wechat-pay-receipt",
  alipayReceipt: "staging-alipay-pay-receipt",
};

const PREMIUM_PRODUCT_IDS = new Set([
  "com.sparksmall.spark.premium.monthly",
  "com.sparksmall.spark.premium.yearly",
]);

function ensurePaymentOrders(state) {
  if (!state.paymentOrders) {
    state.paymentOrders = new Map();
  }
}

function markUserPremium(state, userId) {
  const profileKey = `profile:${userId}`;
  if (!state.profiles) state.profiles = {};
  const profile = state.profiles[profileKey] || { user_id: userId };
  profile.is_premium = true;
  state.profiles[profileKey] = profile;
  if (state.dirty?.profiles) state.dirty.profiles.add(profileKey);

  for (const user of Object.values(state.users || {})) {
    if (user.user_id === userId) {
      user.is_premium = true;
      break;
    }
  }
}

function createStagingPayload(provider) {
  if (provider === "wechat") {
    return {
      partner_id: "staging-partner",
      prepay_id: "staging-prepay",
      package: "Sign=WXPay",
      nonce_str: "staging-nonce",
      timestamp: String(Math.floor(Date.now() / 1000)),
      sign: "staging-sign",
    };
  }
  return {
    order_string: "staging-alipay-order-string",
  };
}

async function verifyPaymentReceipt(provider, receipt) {
  if (!receipt || typeof receipt !== "string") {
    throw paymentError("invalid_request", "Missing payment receipt");
  }
  if (provider === "wechat" && receipt === STAGING_PAYMENTS.wechatReceipt) {
    return { verified: true };
  }
  if (provider === "alipay" && receipt === STAGING_PAYMENTS.alipayReceipt) {
    return { verified: true };
  }
  if (process.env.SPARK_ALLOW_STAGING_PAYMENTS === "1") {
    return { verified: true };
  }
  throw paymentError("verification_failed", `${provider} payment verification not configured`);
}

function paymentError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function registerCNPaymentRoutes(app, { state, requireAuth, err }) {
  ensurePaymentOrders(state);

  app.post("/v1/payments/orders", requireAuth, async (req, res) => {
    try {
      const { product_id: productID, provider } = req.body || {};
      if (!productID || !PREMIUM_PRODUCT_IDS.has(productID)) {
        return err(res, 400, "invalid_request", "Unsupported product_id");
      }
      if (provider !== "wechat" && provider !== "alipay") {
        return err(res, 400, "invalid_request", "provider must be wechat or alipay");
      }
      const orderID = `ord_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      state.paymentOrders.set(orderID, {
        order_id: orderID,
        user_id: req.userId,
        product_id: productID,
        provider,
        status: "pending",
      });
      if (state.dirty) state.dirty.meta = true;
      res.json({
        order_id: orderID,
        provider,
        product_id: productID,
        payload: createStagingPayload(provider),
      });
    } catch (error) {
      mapPaymentError(res, err, error);
    }
  });

  app.post("/v1/payments/confirm", requireAuth, async (req, res) => {
    try {
      const { order_id: orderID, provider, receipt } = req.body || {};
      ensurePaymentOrders(state);
      const order = state.paymentOrders.get(orderID);
      if (!order || order.user_id !== req.userId) {
        return err(res, 404, "order_not_found", "Payment order not found");
      }
      if (order.provider !== provider) {
        return err(res, 400, "invalid_request", "Provider mismatch");
      }
      await verifyPaymentReceipt(provider, receipt);
      order.status = "paid";
      markUserPremium(state, req.userId);
      res.json({ order_id: orderID, status: "paid", is_premium: true });
    } catch (error) {
      mapPaymentError(res, err, error);
    }
  });
}

function mapPaymentError(res, err, error) {
  const code = error.code || "verification_failed";
  const status =
    code === "invalid_request" ? 400 : code === "order_not_found" ? 404 : 402;
  err(res, status, code, error.message || "Payment failed");
}

module.exports = {
  STAGING_PAYMENTS,
  registerCNPaymentRoutes,
};
