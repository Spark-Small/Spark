/**
 * Spark Staging API — CloudBase NoSQL write-through (ADR-0002).
 * Contract: docs/API_CONTRACT.md
 */

const express = require("express");
const crypto = require("crypto");
const {
  hydrate,
  createDirtyTracker,
  persistenceMiddleware,
  persistenceMode,
  persistCommunityReport,
} = require("./lib/persistence");
const { isConfigured: apnsConfigured, sendPushToUser } = require("./lib/apns");
const {
  notifyUser,
  notifyActivityAttendees,
  peerUserIdForDirectThread,
} = require("./lib/push-triggers");
const {
  buildCommunityFeed,
  serializeCommunityDetail,
  serializeCommunityActivities,
  serializeCommunityMembers,
} = require("./lib/community-helpers");
const {
  buildInboxResponse,
  buildConversationContext,
  dismissActionItemForInvite,
  dismissInboxActionItem,
} = require("./lib/messages-helpers");
const phoneOTP = require("./lib/phone-otp");
const {
  buildBuddyListings,
  browseBuddies,
  serializeBuddyListing,
  defaultProviderStatus,
  serializeProviderStatus,
} = require("./lib/buddy-helpers");
const PORT = Number(process.env.PORT) || 9000;

const USER_DISPLAY_NAMES = {
  u_staging_1: "Staging User",
  u_host_1: "阿乐",
  u_host_2: "小雨",
};

const state = {
  users: {},
  activities: new Map(),
  communityPosts: new Map(),
  threads: new Map(),
  viewerProfiles: new Map(),
  mutualMatches: new Map(),
  devices: new Map(),
  counters: {
    msg_counter: 100,
    report_counter: 1,
    activity_report_counter: 1,
    activity_counter: 2,
    post_counter: 3,
    reply_counter: 3,
    community_report_counter: 0,
    buddy_order_counter: 0,
  },
  communityReports: [],
  inboxActionItems: [],
  dismissedInboxActionIds: new Set(),
  phoneOtps: new Map(),
  phoneUsers: new Map(),
  buddies: buildBuddyListings(),
  buddyProviders: new Map(),
  dirty: createDirtyTracker(),
};

function communityRepliesFor(post) {
  return Array.isArray(post.replies) ? post.replies : [];
}

function serializeReply(reply) {
  return {
    id: reply.id,
    body: reply.body,
    author_display_name: reply.author_display_name,
    created_at: reply.created_at,
  };
}

function serializePostDetail(post, viewerUserId) {
  const likers = Array.isArray(post.likers) ? post.likers : [];
  const detail = {
    id: post.id,
    title: post.title,
    body: post.body,
    author_display_name: post.author_display_name,
    author_user_id: post.author_id || null,
    reply_count: post.reply_count,
    like_count: post.like_count ?? likers.length,
    viewer_has_liked: viewerUserId ? likers.includes(viewerUserId) : false,
    replies: communityRepliesFor(post).map(serializeReply),
    kind: post.kind || "discussion",
  };
  if (Array.isArray(post.media) && post.media.length > 0) {
    detail.media = post.media;
  }
  if (post.linked_activity) {
    detail.linked_activity = post.linked_activity;
  } else if (post.id === "cp_001") {
    detail.linked_activity = { id: "act_001", name: "周末爬香山" };
  }
  return detail;
}

function displayNameFor(userId) {
  return USER_DISPLAY_NAMES[userId] || "Spark User";
}

function tokenFor(userId) {
  return `staging_${Buffer.from(userId, "utf8").toString("base64url")}`;
}

function userIdFromToken(token) {
  if (!token || !token.startsWith("staging_")) return null;
  try {
    return Buffer.from(token.slice("staging_".length), "base64url").toString("utf8");
  } catch {
    return null;
  }
}

function touchActivity(id) {
  if (id) state.dirty.activities.add(id);
}

function touchThread(id) {
  if (id) state.dirty.threads.add(id);
}

function touchInbox() {
  state.dirty.inbox = true;
}

function touchMeta() {
  state.dirty.meta = true;
}

function touchCommunityPost(id) {
  if (id) state.dirty.community_posts.add(id);
}

function touchDevice(token) {
  if (token) state.dirty.devices.add(token);
}

function viewerProfileFor(userId) {
  return (
    state.viewerProfiles.get(userId) || {
      display_name: displayNameFor(userId),
      has_photo: true,
    }
  );
}

function isActivityHost(activity, userId) {
  return activity.host_id === userId || activity.rsvp_status === "host";
}

function ensureActivityThread(activity, welcomeMessage) {
  if (!activity.thread_id) {
    activity.thread_id = `th_activity_${activity.id}`;
  }
  if (!state.threads.has(activity.thread_id)) {
    const now = new Date().toISOString();
    state.threads.set(activity.thread_id, {
      id: activity.thread_id,
      peer_display_name: `${activity.title} · 群`,
      last_message_preview: welcomeMessage || "活动群已创建",
      last_activity_at: now,
      unread_count: 0,
      messages: welcomeMessage
        ? [
            {
              id: "msg_sys",
              thread_id: activity.thread_id,
              body: welcomeMessage,
              sent_at: now,
              is_from_current_user: false,
            },
          ]
        : [],
    });
    touchThread(activity.thread_id);
  }
  return activity.thread_id;
}

function err(res, status, code, message) {
  return res.status(status).json({ error: { code, message } });
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  const userId = userIdFromToken(token);
  if (!userId) {
    return err(res, 401, "unauthorized", "Invalid or missing token");
  }
  req.userId = userId;
  next();
}

function optionalAuth(req, _res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  req.userId = userIdFromToken(token);
  next();
}

function buddyProviderFor(userId) {
  return state.buddyProviders.get(userId) || defaultProviderStatus();
}

function activityFeedItem(a) {
  return {
    id: a.id,
    title: a.title,
    summary: a.summary,
    category: a.category,
    starts_at: a.starts_at,
    ends_at: a.ends_at,
    recurrence: a.recurrence,
    location_name: a.location_name,
    host_display_name: a.host_display_name,
    host_id: a.host_id,
    attendee_count: a.attendee_count,
    capacity: a.capacity,
    rsvp_status: a.rsvp_status,
    lifecycle_status: a.lifecycle_status,
    thread_id: a.thread_id,
  };
}

function activityDetail(a) {
  return {
    id: a.id,
    title: a.title,
    summary: a.summary,
    category: a.category,
    description: a.description,
    starts_at: a.starts_at,
    ends_at: a.ends_at,
    recurrence: a.recurrence,
    location_name: a.location_name,
    host_display_name: a.host_display_name,
    host_id: a.host_id,
    host_tier: a.host_tier,
    attendee_count: a.attendee_count,
    waitlisted_count: a.waitlisted_count ?? 0,
    capacity: a.capacity,
    rsvp_status: a.rsvp_status,
    lifecycle_status: a.lifecycle_status,
    thread_id: a.thread_id,
    attendees: a.attendees,
  };
}

function browseActivities(query) {
  const { category, starts_after, starts_before, cursor } = query;
  let items = [...state.activities.values()].filter(
    (a) => a.lifecycle_status !== "cancelled" && a.lifecycle_status !== "ended"
  );
  if (category) {
    items = items.filter((a) => a.category === category);
  }
  if (starts_after) {
    items = items.filter((a) => a.starts_at >= starts_after);
  }
  if (starts_before) {
    items = items.filter((a) => a.starts_at <= starts_before);
  }
  items.sort((a, b) => new Date(a.starts_at) - new Date(b.starts_at));

  const pageSize = 20;
  let startIndex = 0;
  if (cursor) {
    const idx = items.findIndex((a) => a.id === cursor);
    startIndex = idx >= 0 ? idx + 1 : 0;
  }
  const page = items.slice(startIndex, startIndex + pageSize);
  const hasMore = startIndex + pageSize < items.length;
  const next_cursor = hasMore && page.length > 0 ? page[page.length - 1].id : null;
  return { page, next_cursor };
}

const app = express();
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "spark-api",
    env: "staging",
    persistence: persistenceMode(),
    apns_configured: apnsConfigured(),
  });
});

// --- Auth ---

app.post("/v1/auth/email", (req, res) => {
  const { email, password } = req.body || {};
  const user = state.users[email];
  if (!user || user.password !== password) {
    return err(res, 401, "invalid_credentials", "Invalid credentials");
  }
  res.json({ access_token: tokenFor(user.user_id), user_id: user.user_id });
});

app.post("/v1/auth/register", (req, res) => {
  const { email, password, display_name: displayName } = req.body || {};
  const normalizedEmail = typeof email === "string" ? email.trim().toLowerCase() : "";
  if (!normalizedEmail || !password || !displayName?.trim()) {
    return err(res, 400, "invalid_request", "Missing required fields");
  }
  if (password.length < 6) {
    return err(res, 400, "invalid_request", "Password too short");
  }
  if (state.users[normalizedEmail]) {
    return err(res, 409, "email_already_registered", "Email already registered");
  }
  const userId = `u_${Date.now()}`;
  state.users[normalizedEmail] = {
    password,
    user_id: userId,
    name: displayName.trim(),
  };
  touchMeta();
  res.json({ access_token: tokenFor(userId), user_id: userId });
});

app.post("/v1/auth/password-reset", (req, res) => {
  const { email } = req.body || {};
  if (!email || typeof email !== "string" || !email.includes("@")) {
    return err(res, 400, "invalid_request", "Valid email required");
  }
  // REASONING: Staging stub — always 204 to avoid email enumeration.
  res.status(204).send();
});

function isValidCNMobilePhone(phone) {
  return phoneOTP.isValidCNMobilePhone(phone);
}

app.post("/v1/auth/phone/otp", (req, res) => {
  const { phone } = req.body || {};
  const result = phoneOTP.sendPhoneOTP(state, phone);
  if (result.status !== 204) {
    return err(res, result.status, result.code, result.message);
  }
  touchMeta();
  res.status(204).send();
});

app.post("/v1/auth/phone/verify", (req, res) => {
  const { phone, code } = req.body || {};
  if (!isValidCNMobilePhone(phone) || !code) {
    return err(res, 400, "invalid_request", "Valid phone and code required");
  }
  if (!phoneOTP.verifyPhoneOTP(state, phone, code)) {
    return err(res, 401, "invalid_code", "Invalid verification code");
  }
  const user = phoneOTP.ensurePhoneUser(state, phone);
  touchMeta();
  res.json({ access_token: tokenFor(user.user_id), user_id: user.user_id });
});

app.post("/v1/auth/phone/password-reset", (req, res) => {
  const { phone, code, new_password: newPassword } = req.body || {};
  if (
    !isValidCNMobilePhone(phone)
    || !code
    || String(code).length !== phoneOTP.OTP_CODE_LENGTH
    || !newPassword
    || String(newPassword).length < 6
  ) {
    return err(res, 400, "invalid_request", "Valid phone, code, and password required");
  }
  if (!phoneOTP.verifyPhoneOTP(state, phone, code)) {
    return err(res, 401, "invalid_code", "Invalid verification code");
  }
  const user = phoneOTP.setPhoneUserPassword(state, phone, String(newPassword));
  touchMeta();
  res.json({ access_token: tokenFor(user.user_id), user_id: user.user_id });
});

app.get("/v1/auth/session", requireAuth, (req, res) => {
  res.json({ access_token: tokenFor(req.userId), user_id: req.userId });
});

app.post("/v1/auth/sign-out", requireAuth, (_req, res) => {
  res.status(204).send();
});

function purgeUserAccount(userId) {
  for (const [email, user] of Object.entries(state.users)) {
    if (user.user_id === userId) {
      delete state.users[email];
      touchMeta();
    }
  }

  state.viewerProfiles.delete(userId);
  touchInbox();

  for (const [threadId, thread] of state.threads.entries()) {
    const peerId = threadId.startsWith("th_dm_") ? threadId.slice("th_dm_".length) : null;
    if (peerId === userId) {
      state.threads.delete(threadId);
      state.dirty.threads.delete(threadId);
    }
  }

  for (const [postId, post] of state.communityPosts.entries()) {
    if (post.author_id === userId) {
      state.communityPosts.delete(postId);
      state.dirty.community_posts.delete(postId);
    }
  }

  for (const [activityId, activity] of state.activities.entries()) {
    if (activity.host_id === userId) {
      state.activities.delete(activityId);
      state.dirty.activities.delete(activityId);
      if (activity.thread_id) {
        state.threads.delete(activity.thread_id);
        state.dirty.threads.delete(activity.thread_id);
      }
    }
  }

  for (const [token, device] of state.devices.entries()) {
    if (device.user_id === userId) {
      state.devices.delete(token);
      state.dirty.devices.delete(token);
    }
  }

  for (const [key, match] of state.mutualMatches.entries()) {
    if (key.includes(userId)) state.mutualMatches.delete(key);
  }

  phoneOTP.purgePhoneAccount(state, userId);
}

app.post("/v1/auth/account/delete", requireAuth, (req, res) => {
  purgeUserAccount(req.userId);
  res.status(204).send();
});

app.post("/v1/auth/apple", (req, res) => {
  const { identity_token: identityToken } = req.body || {};
  if (!identityToken || typeof identityToken !== "string" || identityToken.length < 10) {
    return err(res, 401, "invalid_apple_token", "Apple identity token required");
  }
  const digest = crypto.createHash("sha256").update(identityToken).digest("hex").slice(0, 16);
  const userId = `apple_${digest}`;
  res.json({ access_token: tokenFor(userId), user_id: userId });
});

// --- Messages ---

app.get("/v1/messages/unread-count", requireAuth, (_req, res) => {
  let count = 0;
  for (const t of state.threads.values()) count += t.unread_count;
  res.json({ count });
});

app.post("/v1/messages/read", requireAuth, (_req, res) => {
  for (const t of state.threads.values()) {
    t.unread_count = 0;
    touchThread(t.id);
  }
  res.status(204).send();
});

app.post("/v1/messages/threads/:threadId/read", requireAuth, (req, res) => {
  const t = state.threads.get(req.params.threadId);
  if (!t) return err(res, 404, "not_found", "Thread not found");
  t.unread_count = 0;
  touchThread(t.id);
  res.status(204).send();
});

app.get("/v1/messages/inbox", requireAuth, (_req, res) => {
  res.json(buildInboxResponse(state));
});

app.post("/v1/messages/inbox/action-items/:actionItemId/dismiss", requireAuth, (req, res) => {
  const ok = dismissInboxActionItem(state, req.params.actionItemId);
  if (!ok) return err(res, 404, "not_found", "Action item not found");
  res.status(204).send();
});

app.get("/v1/messages/threads/:threadId/context", requireAuth, (req, res) => {
  res.json(buildConversationContext(state, req.params.threadId));
});

app.get("/v1/messages/threads", requireAuth, (_req, res) => {
  const list = [...state.threads.values()].map((t) => ({
    id: t.id,
    peer_display_name: t.peer_display_name,
    last_message_preview: t.last_message_preview,
    last_activity_at: t.last_activity_at,
    unread_count: t.unread_count,
  }));
  res.json({ threads: list });
});

app.get("/v1/messages/threads/:threadId/messages", requireAuth, (req, res) => {
  const t = state.threads.get(req.params.threadId);
  if (!t) return err(res, 404, "not_found", "Thread not found");
  res.json({ messages: t.messages });
});

app.post("/v1/messages/threads/:threadId/messages", requireAuth, (req, res) => {
  const t = state.threads.get(req.params.threadId);
  if (!t) return err(res, 404, "not_found", "Thread not found");
  const body = (req.body?.body || "").trim();
  if (!body) return err(res, 400, "invalid_request", "body required");
  state.counters.msg_counter += 1;
  touchMeta();
  const now = new Date().toISOString();
  const msg = {
    id: `msg_${state.counters.msg_counter}`,
    thread_id: t.id,
    body,
    sent_at: now,
    is_from_current_user: true,
  };
  t.messages.push(msg);
  t.last_message_preview = body;
  t.last_activity_at = now;
  touchThread(t.id);
  const peerId = peerUserIdForDirectThread(t.id, req.userId);
  if (peerId) {
    notifyUser(state.devices, peerId, "messages.new", {
      thread_id: t.id,
      body: body.slice(0, 120),
    });
  }
  res.status(201).json(msg);
});

app.post("/v1/messages/activity-threads", requireAuth, (req, res) => {
  const { thread_id, display_name, welcome_message } = req.body || {};
  if (!thread_id) return err(res, 400, "invalid_request", "thread_id required");
  if (!state.threads.has(thread_id)) {
    const now = new Date().toISOString();
    state.threads.set(thread_id, {
      id: thread_id,
      peer_display_name: display_name || "活动群",
      last_message_preview: welcome_message || "欢迎加入活动群聊",
      last_activity_at: now,
      unread_count: 1,
      messages: welcome_message
        ? [
            {
              id: "msg_welcome",
              thread_id,
              body: welcome_message,
              sent_at: now,
              is_from_current_user: false,
            },
          ]
        : [],
    });
    touchThread(thread_id);
  }
  res.status(204).send();
});

app.post("/v1/messages/direct-threads", requireAuth, (req, res) => {
  const peerId = req.body?.peer_user_id;
  const peerName = req.body?.peer_display_name || "好友";
  if (!peerId) return err(res, 400, "invalid_request", "peer_user_id required");
  const threadId = state.mutualMatches.get(peerId) || `th_dm_${peerId}`;
  if (!state.threads.has(threadId)) {
    const now = new Date().toISOString();
    state.threads.set(threadId, {
      id: threadId,
      peer_display_name: peerName,
      last_message_preview: "",
      last_activity_at: now,
      unread_count: 0,
      messages: [],
    });
    touchThread(threadId);
  }
  res.json({ thread_id: threadId });
});

// --- Activities ---

app.get("/v1/activities/feed", requireAuth, (req, res) => {
  const hostId = req.query.host_id;
  let items = [...state.activities.values()];
  if (hostId) {
    items = items.filter((a) => a.host_id === hostId);
  }
  res.json({ items: items.map(activityFeedItem) });
});

app.get("/v1/activities/browse", requireAuth, (req, res) => {
  const { page, next_cursor } = browseActivities(req.query);
  res.json({ items: page.map(activityFeedItem), next_cursor });
});

app.post("/v1/activities", requireAuth, (req, res) => {
  const { title, description, location_name, starts_at, capacity } = req.body || {};
  const trimmedTitle = (title || "").trim();
  if (!trimmedTitle) {
    return err(res, 400, "invalid_request", "title required");
  }
  state.counters.activity_counter += 1;
  touchMeta();
  const id = `act_${String(state.counters.activity_counter).padStart(3, "0")}`;
  const desc = (description || "").trim() || trimmedTitle;
  const activity = {
    id,
    title: trimmedTitle,
    summary: desc.slice(0, 80),
    category: "活动",
    description: desc,
    starts_at: starts_at || new Date().toISOString(),
    location_name: (location_name || "").trim() || "待定",
    host_display_name: displayNameFor(req.userId),
    host_id: req.userId,
    attendee_count: 1,
    waitlisted_count: 0,
    capacity: capacity ?? null,
    rsvp_status: "host",
    lifecycle_status: "scheduled",
    thread_id: null,
    attendees: [
      {
        id: req.userId,
        display_name: displayNameFor(req.userId),
        is_host: true,
        rsvp_status: "host",
      },
    ],
  };
  ensureActivityThread(activity, `欢迎加入「${activity.title}」活动群`);
  state.activities.set(id, activity);
  touchActivity(id);
  res.status(201).json({ activity: activityDetail(activity) });
});

app.get("/v1/activities/:activityId", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  res.json({ activity: activityDetail(a) });
});

app.patch("/v1/activities/:activityId", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  if (!isActivityHost(a, req.userId)) {
    return err(res, 403, "forbidden", "Only the host can update this activity");
  }
  const { title, description, location_name, starts_at, capacity } = req.body || {};
  if (title?.trim()) {
    a.title = title.trim();
    a.summary = a.title;
  }
  if (description?.trim()) {
    a.description = description.trim();
    a.summary = a.description.slice(0, 80);
  }
  if (location_name !== undefined) {
    a.location_name = (location_name || "").trim() || a.location_name;
  }
  if (starts_at) a.starts_at = starts_at;
  if (capacity !== undefined) a.capacity = capacity;
  touchActivity(a.id);
  notifyActivityAttendees(
    state.devices,
    a,
    "activity.updated",
    { body: "活动时间或地点有更新" },
    req.userId
  );
  res.json({ activity: activityDetail(a) });
});

app.post(
  "/v1/activities/:activityId/invitations/:invitationId/respond",
  requireAuth,
  (req, res) => {
    const response = req.body?.response;
    if (!["accept", "decline"].includes(response)) {
      return err(res, 400, "invalid_request", "response must be accept or decline");
    }
    const activity = state.activities.get(req.params.activityId);
    if (!activity) return err(res, 404, "not_found", "Activity not found");
    dismissActionItemForInvite(state, req.params.invitationId);
    if (response === "accept") {
      activity.rsvp_status = "going";
      ensureActivityThread(activity, `欢迎加入「${activity.title}」活动群`);
      activity.attendee_count = Math.max(activity.attendee_count, 1);
      touchActivity(activity.id);
    }
    state.dirty.inbox = true;
    res.status(204).send();
  }
);

app.post("/v1/activities/:activityId/rsvp", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  const status = req.body?.status;
  if (!["going", "maybe", "declined"].includes(status)) {
    return err(res, 400, "invalid_request", "Invalid RSVP status");
  }
  if (a.lifecycle_status === "cancelled") {
    return err(res, 409, "activity_cancelled", "Activity was cancelled");
  }
  a.rsvp_status = status;
  if (status === "going" || status === "maybe") {
    ensureActivityThread(a, `欢迎加入「${a.title}」活动群`);
    a.attendee_count = Math.max(a.attendee_count, 1);
  }
  touchActivity(a.id);
  res.json({ activity: activityDetail(a) });
});

app.post("/v1/activities/:activityId/waitlist", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  if (a.lifecycle_status === "cancelled") {
    return err(res, 409, "activity_cancelled", "Activity was cancelled");
  }
  a.rsvp_status = "waitlisted";
  a.waitlisted_count = (a.waitlisted_count ?? 0) + 1;
  const existing = (a.attendees || []).find((att) => att.id === req.userId);
  if (existing) {
    existing.rsvp_status = "waitlisted";
  } else {
    a.attendees = a.attendees || [];
    a.attendees.push({
      id: req.userId,
      display_name: displayNameFor(req.userId),
      is_host: false,
      rsvp_status: "waitlisted",
    });
  }
  touchActivity(a.id);
  res.json({ activity: activityDetail(a) });
});

app.post("/v1/activities/:activityId/waitlist/:attendeeId/promote", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  if (!isActivityHost(a, req.userId)) {
    return err(res, 403, "forbidden", "Only the host can promote waitlisted attendees");
  }
  const attendee = (a.attendees || []).find((att) => att.id === req.params.attendeeId);
  if (!attendee || attendee.rsvp_status !== "waitlisted") {
    return err(res, 404, "not_found", "Waitlisted attendee not found");
  }
  attendee.rsvp_status = "going";
  a.waitlisted_count = Math.max(0, (a.waitlisted_count ?? 1) - 1);
  a.attendee_count += 1;
  ensureActivityThread(a);
  touchActivity(a.id);
  res.json({ activity: activityDetail(a) });
});

app.post("/v1/activities/:activityId/cancel", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  if (!isActivityHost(a, req.userId)) {
    return err(res, 403, "forbidden", "Only the host can cancel this activity");
  }
  a.lifecycle_status = "cancelled";
  touchActivity(a.id);
  notifyActivityAttendees(
    state.devices,
    a,
    "activity.cancelled",
    { body: `「${a.title}」已取消` },
    req.userId
  );
  res.json({ activity: activityDetail(a) });
});

app.post("/v1/activities/:activityId/report", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  state.counters.activity_report_counter += 1;
  touchMeta();
  res.json({ report_id: `rpt_${state.counters.activity_report_counter}` });
});

app.post("/v1/activities/:activityId/announce", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  if (!isActivityHost(a, req.userId)) {
    return err(res, 403, "forbidden", "Only the host can announce to attendees");
  }
  const message = (req.body?.message || "").trim();
  if (!message) return err(res, 400, "invalid_request", "message required");
  const threadId = ensureActivityThread(a);
  const t = state.threads.get(threadId);
  const now = new Date().toISOString();
  state.counters.msg_counter += 1;
  touchMeta();
  t.messages.push({
    id: `msg_${state.counters.msg_counter}`,
    thread_id: threadId,
    body: message,
    sent_at: now,
    is_from_current_user: false,
  });
  t.last_message_preview = message;
  t.last_activity_at = now;
  touchThread(threadId);
  notifyActivityAttendees(
    state.devices,
    a,
    "activity.updated",
    { body: message.slice(0, 120) },
    req.userId
  );
  res.status(204).send();
});

app.post("/v1/activities/:activityId/feedback", requireAuth, (req, res) => {
  const a = state.activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  if (!isActivityHost(a, req.userId)) {
    return err(res, 403, "forbidden", "Only the host can submit feedback");
  }
  const feedback = req.body?.feedback;
  if (!["positive", "negative"].includes(feedback)) {
    return err(res, 400, "invalid_request", "feedback must be positive or negative");
  }
  res.status(204).send();
});

// --- Search ---

app.get("/v1/search", requireAuth, (req, res) => {
  const q = (req.query.q || "").trim().toLowerCase();
  const results = [];
  if (!q) {
    return res.json({ results });
  }
  for (const a of state.activities.values()) {
    if (a.title.toLowerCase().includes(q) || a.summary.toLowerCase().includes(q)) {
      results.push({
        id: a.id,
        title: a.title,
        subtitle: `${a.category} · ${a.summary}`,
        kind: "activity",
      });
    }
  }
  for (const p of state.communityPosts.values()) {
    if (p.title.toLowerCase().includes(q) || p.excerpt.toLowerCase().includes(q)) {
      results.push({
        id: p.id,
        title: p.title,
        subtitle: p.excerpt,
        kind: "community",
      });
    }
  }
  if (q.includes("小") || q.includes("like")) {
    results.push({
      id: "u_like_2",
      title: "小雨",
      subtitle: "喜欢 · 发现",
      kind: "person",
    });
  }
  res.json({ results });
});

// --- Community ---

app.get("/v1/community/feed", requireAuth, (req, res) => {
  res.json(buildCommunityFeed(state, req.userId));
});

app.get("/v1/community/communities/:communityId", requireAuth, (req, res) => {
  const community = serializeCommunityDetail(req.params.communityId);
  if (!community) return err(res, 404, "not_found", "Community not found");
  res.json({ community });
});

app.get("/v1/community/communities/:communityId/activities", requireAuth, (req, res) => {
  const community = serializeCommunityDetail(req.params.communityId);
  if (!community) return err(res, 404, "not_found", "Community not found");
  res.json({ activities: serializeCommunityActivities(req.params.communityId) });
});

app.get("/v1/community/communities/:communityId/members", requireAuth, (req, res) => {
  const community = serializeCommunityDetail(req.params.communityId);
  if (!community) return err(res, 404, "not_found", "Community not found");
  res.json({ members: serializeCommunityMembers(req.params.communityId) });
});

app.get("/v1/community/posts", requireAuth, (_req, res) => {
  const posts = [...state.communityPosts.values()].map((p) => ({
    id: p.id,
    title: p.title,
    excerpt: p.excerpt,
    author_display_name: p.author_display_name,
    reply_count: p.reply_count,
  }));
  res.json({ posts });
});

app.get("/v1/community/posts/:postId", requireAuth, (req, res) => {
  const p = state.communityPosts.get(req.params.postId);
  if (!p) return err(res, 404, "not_found", "Post not found");
  res.json({ post: serializePostDetail(p, req.userId) });
});

app.post("/v1/community/posts/:postId/like", requireAuth, async (req, res) => {
  const post = state.communityPosts.get(req.params.postId);
  if (!post) return err(res, 404, "not_found", "Post not found");
  const liked = req.body?.liked === true;
  if (!Array.isArray(post.likers)) post.likers = [];
  const hadLiked = post.likers.includes(req.userId);
  if (liked && !hadLiked) {
    post.likers.push(req.userId);
    post.like_count = (post.like_count ?? post.likers.length - 1) + 1;
  } else if (!liked && hadLiked) {
    post.likers = post.likers.filter((id) => id !== req.userId);
    post.like_count = Math.max(0, (post.like_count ?? 1) - 1);
  }
  touchCommunityPost(post.id);
  touchMeta();

  if (liked && !hadLiked && post.author_id && post.author_id !== req.userId) {
    void sendPushToUser(state.devices, post.author_id, "community.like", {
      post_id: post.id,
      title: "有人赞了你的帖子",
      body: `${displayNameFor(req.userId)} 赞了你的局后随拍`.slice(0, 120),
    });
  }

  res.json({
    liked: post.likers.includes(req.userId),
    like_count: post.like_count ?? post.likers.length,
  });
});

app.post("/v1/community/media/stage", requireAuth, (req, res) => {
  const kind = (req.body?.kind || "image").trim();
  const digest = String(req.body?.content_sha256 || "unknown").slice(0, 16);
  if (kind === "video") {
    return res.json({
      id: `vid_${digest}`,
      url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      kind: "video",
      poster_url: `https://picsum.photos/seed/community-video-${digest}/800/450`,
    });
  }
  res.json({
    id: `img_${digest}`,
    url: `https://picsum.photos/seed/community-${digest}/800/450`,
    kind: "image",
  });
});

app.post("/v1/community/posts", requireAuth, (req, res) => {
  const title = (req.body?.title || "").trim();
  const body = (req.body?.body || "").trim();
  const kind = (req.body?.kind || "discussion").trim();
  const activityID = (req.body?.activity_id || "").trim();
  const media = Array.isArray(req.body?.media)
    ? req.body.media
        .filter((item) => item && item.url)
        .map((item, index) => ({
          id: item.id || `media_${index}`,
          url: String(item.url),
          kind: item.kind || "image",
          poster_url: item.poster_url || null,
        }))
    : [];
  if (!title) return err(res, 400, "invalid_request", "title required");
  if (kind === "activity_recap" && !activityID) {
    return err(res, 400, "invalid_request", "activity_id required for activity_recap");
  }
  state.counters.post_counter += 1;
  const id = `cp_${String(state.counters.post_counter).padStart(3, "0")}`;
  const post = {
    id,
    title,
    excerpt: (body || title).slice(0, 80),
    body: body || title,
    author_display_name: displayNameFor(req.userId),
    author_id: req.userId,
    reply_count: 0,
    replies: [],
    kind,
    activity_id: activityID || null,
    media,
  };
  if (kind === "activity_recap" && activityID) {
    const activity = state.activities.get(activityID);
    post.linked_activity = {
      id: activityID,
      name: activity?.title || title,
    };
  }
  state.communityPosts.set(id, post);
  touchCommunityPost(id);
  touchMeta();
  res.status(201).json({
    post: serializePostDetail(post, req.userId),
  });
});

app.post("/v1/community/posts/:postId/replies", requireAuth, async (req, res) => {
  const post = state.communityPosts.get(req.params.postId);
  if (!post) return err(res, 404, "not_found", "Post not found");
  const body = (req.body?.body || "").trim();
  if (!body) return err(res, 400, "invalid_request", "body required");

  state.counters.reply_counter += 1;
  const replyId = `cpr_${String(state.counters.reply_counter).padStart(3, "0")}`;
  const reply = {
    id: replyId,
    body,
    author_display_name: displayNameFor(req.userId),
    author_id: req.userId,
    created_at: new Date().toISOString(),
  };
  if (!Array.isArray(post.replies)) post.replies = [];
  post.replies.push(reply);
  post.reply_count = post.replies.length;
  touchCommunityPost(post.id);
  touchMeta();

  if (post.author_id && post.author_id !== req.userId) {
    void sendPushToUser(state.devices, post.author_id, "community.reply", {
      post_id: post.id,
      title: "帖子有新回复",
      body: body.slice(0, 120),
    });
  }

  res.status(201).json({ reply: serializeReply(reply) });
});

app.post("/v1/community/posts/:postId/report", requireAuth, async (req, res) => {
  const post = state.communityPosts.get(req.params.postId);
  if (!post) return err(res, 404, "not_found", "Post not found");
  const reason = (req.body?.reason || "unspecified").trim().slice(0, 500);
  state.counters.community_report_counter += 1;
  touchMeta();
  const reportId = `cprpt_${String(state.counters.community_report_counter).padStart(3, "0")}`;
  const report = {
    id: reportId,
    post_id: post.id,
    reporter_id: req.userId,
    reason,
    status: "pending",
    created_at: new Date().toISOString(),
  };
  state.communityReports.push(report);
  await persistCommunityReport(report);
  res.status(201).json({ report_id: reportId, status: "pending" });
});

// --- Users / avatar (MODULE-F) ---


app.post("/v1/users/avatar/upload-url", requireAuth, (req, res) => {
  const contentType = req.body?.content_type || "image/jpeg";
  if (!String(contentType).startsWith("image/")) {
    return err(res, 400, "invalid_request", "content_type must be image/*");
  }
  const avatarUrl = `https://picsum.photos/seed/${req.userId}-avatar/400/400`;
  res.json({
    upload_url: null,
    avatar_url: avatarUrl,
    expires_at: new Date(Date.now() + 3600 * 1000).toISOString(),
  });
});

app.patch("/v1/users/profile", requireAuth, (req, res) => {
  const profile = { ...viewerProfileFor(req.userId) };
  if (req.body?.avatar_url) {
    profile.avatar_url = req.body.avatar_url;
    profile.has_photo = true;
  }
  if (req.body?.display_name?.trim()) {
    profile.display_name = req.body.display_name.trim();
  }
  state.viewerProfiles.set(req.userId, profile);
  touchInbox();
  res.json(profile);
});

app.post("/v1/devices", requireAuth, (req, res) => {
  const token = (req.body?.token || "").trim();
  const platform = req.body?.platform || "ios";
  if (!token) return err(res, 400, "invalid_request", "token required");
  state.devices.set(token, {
    user_id: req.userId,
    platform,
    updated_at: new Date().toISOString(),
  });
  touchDevice(token);
  res.status(204).send();
});

app.post("/v1/notifications/send", requireAuth, async (req, res) => {
  const { user_id: targetUserId, type, payload } = req.body || {};
  if (!targetUserId || !type) {
    return err(res, 400, "invalid_request", "user_id and type required");
  }
  if (!apnsConfigured()) {
    return res.status(202).json({
      queued: true,
      apns_configured: false,
      user_id: targetUserId,
      type,
      payload: payload || {},
    });
  }
  try {
    const result = await sendPushToUser(
      state.devices,
      targetUserId,
      type,
      payload || {}
    );
    if (result.sent === 0 && result.reason === "no_devices") {
      return res.status(202).json({
        queued: true,
        apns_configured: true,
        user_id: targetUserId,
        type,
        payload: payload || {},
        reason: "no_devices",
      });
    }
    return res.status(200).json({
      queued: false,
      apns_configured: true,
      user_id: targetUserId,
      type,
      sent: result.sent,
      failed: result.failed,
      errors: result.errors,
    });
  } catch (error) {
    console.error("notifications/send failed", error);
    return err(res, 502, "push_failed", error.message || "APNs delivery failed");
  }
});

// --- Trust (Nexus W4 staging MVP) ---

// --- Buddy (搭子) ---

app.get("/v1/buddies", optionalAuth, (req, res) => {
  const { page, nextCursor } = browseBuddies(state.buddies, req.query);
  res.json({
    items: page.map(serializeBuddyListing),
    nextCursor,
  });
});

app.get("/v1/buddies/:buddyId", optionalAuth, (req, res) => {
  const listing = state.buddies.get(req.params.buddyId);
  if (!listing) return err(res, 404, "not_found", "Buddy listing not found");
  res.json(serializeBuddyListing(listing));
});

app.post("/v1/buddy-orders", requireAuth, (req, res) => {
  const { listingID, packageID, scheduledAt } = req.body || {};
  const trimmedListingID = (listingID || "").trim();
  const trimmedPackageID = (packageID || "").trim();
  if (!trimmedListingID || !trimmedPackageID || !scheduledAt) {
    return err(res, 400, "invalid_request", "listingID, packageID, and scheduledAt required");
  }
  const listing = state.buddies.get(trimmedListingID);
  if (!listing) return err(res, 404, "not_found", "Buddy listing not found");
  const pkg = (listing.packages || []).find((item) => item.id === trimmedPackageID);
  if (!pkg) return err(res, 400, "invalid_request", "Unknown packageID");
  state.counters.buddy_order_counter += 1;
  const orderId = `buddy_order_${state.counters.buddy_order_counter}`;
  res.status(201).json({
    id: orderId,
    listingID: trimmedListingID,
    packageID: trimmedPackageID,
    escrowHeld: true,
  });
});

app.get("/v1/buddy-provider/status", requireAuth, (req, res) => {
  res.json(serializeProviderStatus(buddyProviderFor(req.userId)));
});

app.post("/v1/buddy-provider/application", requireAuth, (req, res) => {
  const { displayName, city, serviceCategory, bio } = req.body || {};
  if (!(displayName || "").trim() || !(city || "").trim() || !(serviceCategory || "").trim()) {
    return err(res, 400, "invalid_request", "displayName, city, and serviceCategory required");
  }
  if (!(bio || "").trim()) {
    return err(res, 400, "invalid_request", "bio required");
  }
  const now = new Date().toISOString();
  const status = {
    state: "approved",
    submittedAt: now,
    reviewedAt: now,
    rejectionReason: null,
  };
  state.buddyProviders.set(req.userId, status);
  res.json(serializeProviderStatus(status));
});

app.get("/v1/buddy-provider/earnings", requireAuth, (req, res) => {
  const status = buddyProviderFor(req.userId);
  if (status.state !== "approved") {
    return err(res, 403, "forbidden", "Provider approval required");
  }
  res.json({
    availableBalance: "1280.00",
    pendingEscrow: "399.00",
    currencyCode: "CNY",
    completedOrderCount: 12,
    monthEarnings: "2450.00",
  });
});

app.get("/v1/buddy-provider/orders", requireAuth, (req, res) => {
  const status = buddyProviderFor(req.userId);
  if (status.state !== "approved") {
    return err(res, 403, "forbidden", "Provider approval required");
  }
  res.json([
    {
      id: "provider_order_1",
      guestDisplayName: "Staging User",
      packageTitle: "城市漫游",
      scheduledAt: "2026-07-10T10:00:00Z",
      amount: "299",
      currencyCode: "CNY",
      state: "confirmed",
    },
  ]);
});

app.get("/v1/trust/profile", requireAuth, (req, res) => {
  res.json({
    profile: {
      trust_score: 42,
      activity_attendance_count: 2,
      completed_levels: ["phone"],
      has_liveness_verification: false,
    },
  });
});

app.post("/v1/trust/phone/verify", requireAuth, (req, res) => {
  const code = (req.body?.code || "").trim();
  if (!code) return err(res, 400, "invalid_request", "code required");
  res.json({ outcome: "verified" });
});

app.post("/v1/trust/real-name", requireAuth, (req, res) => {
  const name = (req.body?.legal_name || "").trim();
  const idNumber = (req.body?.id_number || "").trim();
  if (!name || !idNumber) return err(res, 400, "invalid_request", "legal_name and id_number required");
  res.json({ outcome: "verified" });
});

app.post("/v1/trust/liveness/verify", requireAuth, (_req, res) => {
  res.json({ outcome: "verified", has_liveness_verification: true });
});

app.use((req, res) => {
  err(res, 404, "not_found", `No route ${req.method} ${req.path}`);
});

async function main() {
  const loadInfo = await hydrate(state);
  console.log(`persistence: ${loadInfo.mode}${loadInfo.seeded ? " (seeded)" : ""}`);
  app.use(persistenceMiddleware(state, () => state.dirty));
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`spark-api listening on ${PORT}`);
  });
}

main().catch((error) => {
  console.error("spark-api failed to start", error);
  process.exit(1);
});
