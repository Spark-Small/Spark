/**
 * Spark Staging API — in-memory MVP for iOS Live* repositories.
 * Contract: docs/API_CONTRACT.md
 */

const express = require("express");
const {
  buildInboxResponse,
  buildConversationContext,
  dismissActionItemForInvite,
  defaultInboxActionItems,
} = require("./lib/messages-helpers");
const { registerAuthRoutes } = require("./lib/auth-providers");
const { registerCNPaymentRoutes } = require("./lib/cn-payments");

// CloudBase HTTP 云函数要求监听 9000；云托管可设 PORT=3000
const PORT = Number(process.env.PORT) || 9000;

// --- Seed data ---

const USERS = {
  "staging@test.com": { password: "staging123", user_id: "u_staging_1", name: "Staging User" },
};

const USER_DISPLAY_NAMES = {
  u_staging_1: "Staging User",
  u_host_1: "阿乐",
  u_host_2: "小雨",
};

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

const activities = new Map([
  [
    "act_001",
    {
      id: "act_001",
      title: "周末徒步",
      summary: "城郊步道 · 周六上午",
      category: "活动",
      description: "集合后统一出发，自备饮水。",
      starts_at: "2026-06-07T09:30:00Z",
      location_name: "城郊步道北门",
      host_display_name: "阿乐",
      host_id: "u_host_1",
      attendee_count: 5,
      capacity: 8,
      rsvp_status: "invited",
      lifecycle_status: "scheduled",
      thread_id: "th_activity_act_001",
      attendees: [
        { id: "u_host_1", display_name: "阿乐", is_host: true, rsvp_status: "host" },
        { id: "u_staging_1", display_name: "Staging User", is_host: false, rsvp_status: "invited" },
      ],
    },
  ],
  [
    "act_002",
    {
      id: "act_002",
      title: "Staging 咖啡局",
      summary: "静安 · 周五傍晚",
      category: "社交",
      description: "轻松聊天，认识新朋友。",
      starts_at: "2026-06-10T11:00:00Z",
      location_name: "静安寺商圈",
      host_display_name: "小雨",
      host_id: "u_host_2",
      attendee_count: 2,
      capacity: 2,
      waitlisted_count: 1,
      rsvp_status: "invited",
      lifecycle_status: "scheduled",
      thread_id: "th_activity_act_002",
      attendees: [
        { id: "u_host_2", display_name: "小雨", is_host: true, rsvp_status: "host" },
        { id: "u_guest_1", display_name: "排队君", is_host: false, rsvp_status: "waitlisted" },
      ],
    },
  ],
]);

const communityPosts = new Map([
  [
    "cp_001",
    {
      id: "cp_001",
      title: "周末去哪玩？",
      excerpt: "城郊徒步局还差两人",
      body: "城郊步道周六上午集合，还差两人。",
      author_display_name: "阿乐",
      reply_count: 12,
    },
  ],
  [
    "cp_002",
    {
      id: "cp_002",
      title: "找饭搭子",
      excerpt: "静安寺附近晚餐",
      body: "本周五想找人一起吃饭聊天。",
      author_display_name: "小雨",
      reply_count: 5,
    },
  ],
  [
    "cp_003",
    {
      id: "cp_003",
      title: "运动打卡",
      excerpt: "晨跑小组招募",
      body: "每周三次晨跑，欢迎加入。",
      author_display_name: "阿乐",
      reply_count: 8,
    },
  ],
]);

const threads = new Map([
  [
    "th_dm_u_like_1",
    {
      id: "th_dm_u_like_1",
      peer_display_name: "阿乐",
      last_message_preview: "",
      last_activity_at: "2026-06-05T08:00:00Z",
      unread_count: 0,
      messages: [],
    },
  ],
  [
    "th_dm_u_like_2",
    {
      id: "th_dm_u_like_2",
      peer_display_name: "小雨",
      last_message_preview: "周六一起爬山吗？",
      last_activity_at: "2026-06-04T10:00:00Z",
      unread_count: 1,
      is_partner_online: true,
      messages: [
        {
          id: "msg_dm_001",
          thread_id: "th_dm_u_like_2",
          body: "周六一起爬山吗？",
          sent_at: "2026-06-04T10:00:00Z",
          is_from_current_user: false,
        },
      ],
    },
  ],
  [
    "th_activity_act_001",
    {
      id: "th_activity_act_001",
      peer_display_name: "周末徒步 · 群",
      last_message_preview: "周六 9:30 北门集合",
      last_activity_at: "2026-06-04T09:30:00Z",
      unread_count: 1,
      member_count: 5,
      messages: [
        {
          id: "msg_grp_001",
          thread_id: "th_activity_act_001",
          body: "周六 9:30 北门集合",
          sent_at: "2026-06-04T09:30:00Z",
          is_from_current_user: false,
        },
      ],
    },
  ],
  [
    "th_activity_act_002",
    {
      id: "th_activity_act_002",
      peer_display_name: "Staging 咖啡局 · 群",
      last_message_preview: "欢迎加入活动群聊",
      last_activity_at: "2026-06-03T18:00:00Z",
      unread_count: 0,
      member_count: 2,
      messages: [
        {
          id: "msg_grp_002",
          thread_id: "th_activity_act_002",
          body: "欢迎加入活动群聊",
          sent_at: "2026-06-03T18:00:00Z",
          is_from_current_user: false,
        },
      ],
    },
  ],
]);

const likesCards = [
  {
    user_id: "u_like_1",
    display_name: "阿乐",
    bio: "徒步、摄影",
    gender: "male",
    media: { kind: "image", url: "https://picsum.photos/seed/spark-like-1/1080/1440", poster_url: null },
  },
  {
    user_id: "u_like_2",
    display_name: "小雨",
    bio: "咖啡、聊天、慢生活",
    gender: "female",
    media: { kind: "image", url: "https://picsum.photos/seed/spark-like-2/1080/1440", poster_url: null },
  },
  {
    user_id: "u_like_3",
    display_name: "小晨",
    bio: "城市漫步",
    gender: "female",
    media: { kind: "image", url: "https://picsum.photos/seed/spark-like-3/1080/1440", poster_url: null },
  },
];

const inboundLikes = [
  {
    user_id: "u_like_5",
    liked_at: "2026-06-05T12:00:00Z",
    card: {
      user_id: "u_like_5",
      display_name: "小晨",
      bio: "想认识你",
      gender: "female",
      media: { kind: "image", url: "https://picsum.photos/seed/spark-like-5/1080/1440", poster_url: null },
    },
  },
];

const viewerProfiles = new Map();
const passedUsers = new Set();
const likedByMe = new Set();
const mutualMatches = new Map([
  ["u_like_1", "th_dm_u_like_1"],
  ["u_like_2", "th_dm_u_like_2"],
]);
let inboxActionItems = defaultInboxActionItems(activities);
const dismissedInboxActionIds = new Set();

function messagesState() {
  return {
    threads,
    activities,
    likesCards,
    mutualMatches,
    inboxActionItems,
    dismissedInboxActionIds,
  };
}

let msgCounter = 100;
let reportCounter = 1;
let activityReportCounter = 1;
let activityCounter = 2;
let lastPassUserId = null;
let rewindUsedToday = false;

function isActivityHost(activity, userId) {
  return activity.host_id === userId || activity.rsvp_status === "host";
}

function ensureActivityThread(activity, welcomeMessage) {
  if (!activity.thread_id) {
    activity.thread_id = `th_activity_${activity.id}`;
  }
  if (!threads.has(activity.thread_id)) {
    const now = new Date().toISOString();
    threads.set(activity.thread_id, {
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

function activityFeedItem(a) {
  return {
    id: a.id,
    title: a.title,
    summary: a.summary,
    category: a.category,
    starts_at: a.starts_at,
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
    location_name: a.location_name,
    host_display_name: a.host_display_name,
    host_id: a.host_id,
    attendee_count: a.attendee_count,
    waitlisted_count: a.waitlisted_count ?? 0,
    capacity: a.capacity,
    rsvp_status: a.rsvp_status,
    lifecycle_status: a.lifecycle_status,
    thread_id: a.thread_id,
    attendees: a.attendees,
  };
}

const app = express();
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "spark-api", env: "staging" });
});

// --- Auth ---

app.post("/v1/auth/email", (req, res) => {
  const { email, password } = req.body || {};
  const user = USERS[email];
  if (!user || user.password !== password) {
    return err(res, 401, "invalid_credentials", "Invalid credentials");
  }
  res.json({ access_token: tokenFor(user.user_id), user_id: user.user_id });
});

app.get("/v1/auth/session", requireAuth, (req, res) => {
  res.json({ access_token: tokenFor(req.userId), user_id: req.userId });
});

app.post("/v1/auth/sign-out", requireAuth, (_req, res) => {
  res.status(204).send();
});

app.post("/v1/auth/apple", (_req, res) => {
  const userId = "u_staging_1";
  res.json({ access_token: tokenFor(userId), user_id: userId });
});

const authState = {
  users: USERS,
  usersByProvider: new Map(),
  counters: { user_counter: 100 },
};
registerAuthRoutes(app, { state: authState, tokenFor, err });
registerCNPaymentRoutes(app, { state: authState, requireAuth, err });

// --- Messages ---

app.get("/v1/messages/unread-count", requireAuth, (_req, res) => {
  let count = 0;
  for (const t of threads.values()) count += t.unread_count;
  res.json({ count });
});

app.post("/v1/messages/read", requireAuth, (_req, res) => {
  for (const t of threads.values()) t.unread_count = 0;
  res.status(204).send();
});

app.post("/v1/messages/threads/:threadId/read", requireAuth, (req, res) => {
  const t = threads.get(req.params.threadId);
  if (!t) return err(res, 404, "not_found", "Thread not found");
  t.unread_count = 0;
  res.status(204).send();
});

app.get("/v1/messages/inbox", requireAuth, (_req, res) => {
  res.json(buildInboxResponse(messagesState()));
});

app.get("/v1/messages/threads/:threadId/context", requireAuth, (req, res) => {
  res.json(buildConversationContext(messagesState(), req.params.threadId));
});

app.get("/v1/messages/threads", requireAuth, (_req, res) => {
  const list = [...threads.values()].map((t) => ({
    id: t.id,
    peer_display_name: t.peer_display_name,
    last_message_preview: t.last_message_preview,
    last_activity_at: t.last_activity_at,
    unread_count: t.unread_count,
  }));
  res.json({ threads: list });
});

app.get("/v1/messages/threads/:threadId/messages", requireAuth, (req, res) => {
  const t = threads.get(req.params.threadId);
  if (!t) return err(res, 404, "not_found", "Thread not found");
  res.json({ messages: t.messages });
});

app.post("/v1/messages/threads/:threadId/messages", requireAuth, (req, res) => {
  const t = threads.get(req.params.threadId);
  if (!t) return err(res, 404, "not_found", "Thread not found");
  const body = (req.body?.body || "").trim();
  if (!body) return err(res, 400, "invalid_request", "body required");
  msgCounter += 1;
  const now = new Date().toISOString();
  const msg = {
    id: `msg_${msgCounter}`,
    thread_id: t.id,
    body,
    sent_at: now,
    is_from_current_user: true,
  };
  t.messages.push(msg);
  t.last_message_preview = body;
  t.last_activity_at = now;
  res.status(201).json(msg);
});

app.post("/v1/messages/activity-threads", requireAuth, (req, res) => {
  const { thread_id, display_name, welcome_message } = req.body || {};
  if (!thread_id) return err(res, 400, "invalid_request", "thread_id required");
  if (!threads.has(thread_id)) {
    const now = new Date().toISOString();
    threads.set(thread_id, {
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
  }
  res.status(204).send();
});

app.post("/v1/messages/direct-threads", requireAuth, (req, res) => {
  const peerId = req.body?.peer_user_id;
  const peerName = req.body?.peer_display_name || "好友";
  if (!peerId) return err(res, 400, "invalid_request", "peer_user_id required");
  const threadId = mutualMatches.get(peerId) || `th_dm_${peerId}`;
  if (!threads.has(threadId)) {
    const now = new Date().toISOString();
    threads.set(threadId, {
      id: threadId,
      peer_display_name: peerName,
      last_message_preview: "",
      last_activity_at: now,
      unread_count: 0,
      messages: [],
    });
  }
  res.json({ thread_id: threadId });
});

// --- Activities ---

app.get("/v1/activities/feed", requireAuth, (req, res) => {
  const hostId = req.query.host_id;
  let items = [...activities.values()];
  if (hostId) {
    items = items.filter((a) => a.host_id === hostId);
  }
  res.json({ items: items.map(activityFeedItem) });
});

app.post("/v1/activities", requireAuth, (req, res) => {
  const { title, description, location_name, starts_at, capacity } = req.body || {};
  const trimmedTitle = (title || "").trim();
  if (!trimmedTitle) {
    return err(res, 400, "invalid_request", "title required");
  }
  activityCounter += 1;
  const id = `act_${String(activityCounter).padStart(3, "0")}`;
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
  activities.set(id, activity);
  res.status(201).json({ activity: activityDetail(activity) });
});

app.get("/v1/activities/:activityId", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  res.json({ activity: activityDetail(a) });
});

app.patch("/v1/activities/:activityId", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
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
    const activity = activities.get(req.params.activityId);
    if (!activity) return err(res, 404, "not_found", "Activity not found");
    dismissActionItemForInvite(messagesState(), req.params.invitationId);
    if (response === "accept") {
      activity.rsvp_status = "going";
      ensureActivityThread(activity, `欢迎加入「${activity.title}」活动群`);
      activity.attendee_count = Math.max(activity.attendee_count, 1);
    }
    res.status(204).send();
  }
);

app.post("/v1/activities/:activityId/rsvp", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
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
  res.json({ activity: activityDetail(a) });
});

app.post("/v1/activities/:activityId/waitlist", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
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
  res.json({ activity: activityDetail(a) });
});

app.post("/v1/activities/:activityId/waitlist/:attendeeId/promote", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
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
  res.json({ activity: activityDetail(a) });
});

app.post("/v1/activities/:activityId/cancel", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  if (!isActivityHost(a, req.userId)) {
    return err(res, 403, "forbidden", "Only the host can cancel this activity");
  }
  a.lifecycle_status = "cancelled";
  res.json({ activity: activityDetail(a) });
});

app.post("/v1/activities/:activityId/report", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  activityReportCounter += 1;
  res.json({ report_id: `rpt_${activityReportCounter}` });
});

app.post("/v1/activities/:activityId/announce", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
  if (!a) return err(res, 404, "not_found", "Activity not found");
  if (!isActivityHost(a, req.userId)) {
    return err(res, 403, "forbidden", "Only the host can announce to attendees");
  }
  const message = (req.body?.message || "").trim();
  if (!message) return err(res, 400, "invalid_request", "message required");
  const threadId = ensureActivityThread(a);
  const t = threads.get(threadId);
  const now = new Date().toISOString();
  msgCounter += 1;
  t.messages.push({
    id: `msg_${msgCounter}`,
    thread_id: threadId,
    body: message,
    sent_at: now,
    is_from_current_user: false,
  });
  t.last_message_preview = message;
  t.last_activity_at = now;
  res.status(204).send();
});

app.post("/v1/activities/:activityId/feedback", requireAuth, (req, res) => {
  const a = activities.get(req.params.activityId);
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
  for (const a of activities.values()) {
    if (a.title.toLowerCase().includes(q) || a.summary.toLowerCase().includes(q)) {
      results.push({
        id: a.id,
        title: a.title,
        subtitle: `${a.category} · ${a.summary}`,
        kind: "activity",
      });
    }
  }
  for (const p of communityPosts.values()) {
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

app.get("/v1/community/posts", requireAuth, (_req, res) => {
  const posts = [...communityPosts.values()].map((p) => ({
    id: p.id,
    title: p.title,
    excerpt: p.excerpt,
    author_display_name: p.author_display_name,
    reply_count: p.reply_count,
  }));
  res.json({ posts });
});

app.get("/v1/community/posts/:postId", requireAuth, (req, res) => {
  const p = communityPosts.get(req.params.postId);
  if (!p) return err(res, 404, "not_found", "Post not found");
  res.json({
    post: {
      id: p.id,
      title: p.title,
      body: p.body,
      author_display_name: p.author_display_name,
      reply_count: p.reply_count,
    },
  });
});

// --- Likes ---

function feedCards() {
  return likesCards.filter((c) => !passedUsers.has(c.user_id));
}

app.get("/v1/likes/feed", requireAuth, (req, res) => {
  const items = feedCards();
  const cursor = req.query.cursor;
  if (cursor) {
    return res.status(204).send();
  }
  res.json({ items, next_cursor: items.length > 0 ? "c_page_2" : null });
});

app.get("/v1/likes/inbound", requireAuth, (_req, res) => {
  res.json({ items: inboundLikes, next_cursor: null });
});

app.get("/v1/likes/viewer-profile", requireAuth, (req, res) => {
  const profile = viewerProfiles.get(req.userId) || {
    display_name: "Staging User",
    has_photo: true,
  };
  res.json(profile);
});

app.patch("/v1/likes/viewer-profile", requireAuth, (req, res) => {
  const profile = {
    display_name: req.body?.display_name || "Staging User",
    has_photo: Boolean(req.body?.has_photo),
  };
  viewerProfiles.set(req.userId, profile);
  res.json(profile);
});

app.post("/v1/likes/rewind", requireAuth, (_req, res) => {
  if (rewindUsedToday || !lastPassUserId) {
    return res.json({ card: null });
  }
  rewindUsedToday = true;
  passedUsers.delete(lastPassUserId);
  const card = likesCards.find((c) => c.user_id === lastPassUserId) || null;
  res.json({ card });
});

app.post("/v1/likes/:userId/like", requireAuth, (req, res) => {
  const target = req.params.userId;
  likedByMe.add(target);
  if (mutualMatches.has(target) || target === "u_like_2") {
    const threadId = mutualMatches.get(target) || `th_dm_${target}`;
    mutualMatches.set(target, threadId);
    return res.json({ outcome: "matched", thread_id: threadId });
  }
  return res.json({ outcome: "pending", thread_id: null });
});

app.post("/v1/likes/:userId/pass", requireAuth, (req, res) => {
  lastPassUserId = req.params.userId;
  passedUsers.add(req.params.userId);
  res.status(204).send();
});

app.post("/v1/likes/:userId/friend-request", requireAuth, (req, res) => {
  const target = req.params.userId;
  if (mutualMatches.has(target)) {
    return err(res, 409, "already_connected", "Already connected");
  }
  res.json({ outcome: "sent" });
});

app.post("/v1/likes/:userId/report", requireAuth, (req, res) => {
  reportCounter += 1;
  res.json({ report_id: `rp_${reportCounter}` });
});

app.post("/v1/likes/:userId/block", requireAuth, (req, res) => {
  passedUsers.add(req.params.userId);
  res.status(204).send();
});

app.post("/v1/devices", requireAuth, (_req, res) => {
  res.status(204).send();
});

app.use((req, res) => {
  err(res, 404, "not_found", `No route ${req.method} ${req.path}`);
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`spark-api listening on ${PORT}`);
});
