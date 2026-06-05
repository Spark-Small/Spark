/**
 * CloudBase NoSQL write-through persistence (ADR-0002).
 * REASONING: Maps stay the source of truth per request; flush on response finish.
 */

const { buildSeed } = require("./seed-data");

const COLLECTION = {
  users: "spark_users",
  activities: "spark_activities",
  threads: "spark_threads",
  community_posts: "spark_community_posts",
  likes_state: "spark_likes_state",
  devices: "spark_devices",
  community_reports: "spark_community_reports",
  meta: "spark_meta",
};

const LIKES_DOC_ID = "global";

function persistenceMode() {
  if (process.env.SPARK_PERSISTENCE === "memory") return "memory";
  if (process.env.TCB_ENV || process.env.SCF_NAMESPACE) return "cloudbase";
  return "memory";
}

let db = null;

function getDatabase() {
  if (db) return db;
  if (persistenceMode() !== "cloudbase") return null;
  // REASONING: Lazy require — local dev without SDK still runs in memory mode.
  const cloudbase = require("@cloudbase/node-sdk");
  const env = process.env.TCB_ENV || process.env.SCF_NAMESPACE;
  db = cloudbase.init({ env }).database();
  return db;
}

function createDirtyTracker() {
  return {
    users: new Set(),
    activities: new Set(),
    threads: new Set(),
    community_posts: new Set(),
    devices: new Set(),
    likes: false,
    meta: false,
  };
}

function applySeed(state) {
  const seed = buildSeed();
  state.users = seed.users;
  state.activities = seed.activities;
  state.communityPosts = seed.communityPosts;
  state.threads = seed.threads;
  state.likesCards = seed.likesState.cards;
  state.inboundLikes = seed.likesState.inbound;
  state.viewerProfiles = new Map(Object.entries(seed.likesState.viewer_profiles));
  state.passedUsers = new Set(seed.likesState.passed_users);
  state.likedByMe = new Set(seed.likesState.liked_by_me);
  state.mutualMatches = new Map(Object.entries(seed.likesState.mutual_matches));
  state.lastPassUserId = seed.likesState.last_pass_user_id;
  state.rewindUsedToday = seed.likesState.rewind_used_today;
  state.inboundByUser = new Map(
    Object.entries(seed.likesState.inbound_by_user || {})
  );
  state.passedByUser = require("./likes-helpers").mapsFromObjectSets(
    seed.likesState.passed_by_user
  );
  state.likedByMeByUser = require("./likes-helpers").mapsFromObjectSets(
    seed.likesState.liked_by_user
  );
  state.dailyByUser = require("./likes-helpers").mapsFromObjectPlain(
    seed.likesState.daily_by_user
  );
  state.rewindByUser = new Map(Object.entries(seed.likesState.rewind_by_user || {}));
  Object.assign(state.counters, seed.meta);
}

async function loadCollection(database, name, intoMap, idField = "id") {
  const snapshot = await database.collection(name).get();
  for (const doc of snapshot.data || []) {
    const key = doc[idField] || doc._id;
    const { _id, ...rest } = doc;
    intoMap.set(key, rest[idField] ? rest : { ...rest, [idField]: key });
  }
}

async function loadUsers(database, intoObject) {
  const snapshot = await database.collection(COLLECTION.users).get();
  for (const doc of snapshot.data || []) {
    const email = doc._id;
    const { _id, ...rest } = doc;
    intoObject[email] = rest;
  }
}

async function loadDevices(database, intoMap) {
  const snapshot = await database.collection(COLLECTION.devices).get();
  for (const doc of snapshot.data || []) {
    const token = doc._id || doc.token;
    if (!token) continue;
    const { _id, token: _token, ...rest } = doc;
    intoMap.set(token, rest);
  }
}

function serializeLikesState(state) {
  const { mapsToObject } = require("./likes-helpers");
  return {
    _id: LIKES_DOC_ID,
    cards: state.likesCards,
    inbound: state.inboundLikes,
    inbound_by_user: Object.fromEntries(state.inboundByUser || new Map()),
    viewer_profiles: Object.fromEntries(state.viewerProfiles),
    passed_users: [...state.passedUsers],
    passed_by_user: mapsToObject(state.passedByUser || new Map()),
    liked_by_me: [...state.likedByMe],
    liked_by_user: mapsToObject(state.likedByMeByUser || new Map()),
    daily_by_user: mapsToObject(state.dailyByUser || new Map()),
    mutual_matches: Object.fromEntries(state.mutualMatches),
    last_pass_user_id: state.lastPassUserId,
    rewind_used_today: state.rewindUsedToday,
    rewind_by_user: Object.fromEntries(state.rewindByUser || new Map()),
  };
}

function applyLikesDoc(state, doc) {
  if (!doc) return;
  const { mapsFromObjectSets, mapsFromObjectPlain } = require("./likes-helpers");
  state.likesCards = doc.cards || state.likesCards;
  state.inboundLikes = doc.inbound || state.inboundLikes;
  if (doc.inbound_by_user) {
    state.inboundByUser = new Map(Object.entries(doc.inbound_by_user));
  } else if (doc.inbound?.length) {
    state.inboundByUser = new Map([["u_staging_1", doc.inbound]]);
  } else {
    state.inboundByUser = state.inboundByUser || new Map();
  }
  state.viewerProfiles = new Map(Object.entries(doc.viewer_profiles || {}));
  state.passedUsers = new Set(doc.passed_users || []);
  state.passedByUser = mapsFromObjectSets(doc.passed_by_user);
  state.likedByMe = new Set(doc.liked_by_me || []);
  state.likedByMeByUser = mapsFromObjectSets(doc.liked_by_user);
  state.dailyByUser = mapsFromObjectPlain(doc.daily_by_user);
  state.mutualMatches = new Map(Object.entries(doc.mutual_matches || {}));
  state.lastPassUserId = doc.last_pass_user_id ?? null;
  state.rewindUsedToday = Boolean(doc.rewind_used_today);
  state.rewindByUser = new Map(Object.entries(doc.rewind_by_user || {}));
}

async function hydrate(state) {
  const database = getDatabase();
  if (!database) {
    applySeed(state);
    return { mode: "memory", seeded: true };
  }

  try {
    await loadUsers(database, state.users);
    await loadCollection(database, COLLECTION.activities, state.activities);
    await loadCollection(database, COLLECTION.threads, state.threads);
    await loadCollection(database, COLLECTION.community_posts, state.communityPosts);
    if (state.devices) {
      await loadDevices(database, state.devices);
    }

    const likesSnap = await database.collection(COLLECTION.likes_state).doc(LIKES_DOC_ID).get();
    applyLikesDoc(state, likesSnap.data?.[0]);

    const metaSnap = await database.collection(COLLECTION.meta).doc("counters").get();
    const metaDoc = metaSnap.data?.[0];
    if (metaDoc) Object.assign(state.counters, metaDoc);

    if (state.activities.size === 0) {
      applySeed(state);
      await persistAll(state);
      return { mode: "cloudbase", seeded: true };
    }
    return { mode: "cloudbase", seeded: false };
  } catch (error) {
    console.error("persistence hydrate failed, falling back to seed", error);
    applySeed(state);
    return { mode: "cloudbase-fallback", seeded: true };
  }
}

async function persistAll(state) {
  const database = getDatabase();
  if (!database) return;

  for (const [email, user] of Object.entries(state.users)) {
    await database.collection(COLLECTION.users).doc(email).set(user);
  }
  for (const activity of state.activities.values()) {
    await database.collection(COLLECTION.activities).doc(activity.id).set(activity);
  }
  for (const thread of state.threads.values()) {
    await database.collection(COLLECTION.threads).doc(thread.id).set(thread);
  }
  for (const post of state.communityPosts.values()) {
    await database.collection(COLLECTION.community_posts).doc(post.id).set(post);
  }
  await database.collection(COLLECTION.likes_state).doc(LIKES_DOC_ID).set(serializeLikesState(state));
  if (state.devices) {
    for (const [token, device] of state.devices.entries()) {
      await database.collection(COLLECTION.devices).doc(token).set({ ...device, token });
    }
  }
  await database.collection(COLLECTION.meta).doc("counters").set(state.counters);
}

async function flush(state, dirty) {
  const database = getDatabase();
  if (!database) return;

  try {
    for (const email of dirty.users) {
      await database.collection(COLLECTION.users).doc(email).set(state.users[email]);
    }
    for (const id of dirty.activities) {
      const activity = state.activities.get(id);
      if (activity) await database.collection(COLLECTION.activities).doc(id).set(activity);
    }
    for (const id of dirty.threads) {
      const thread = state.threads.get(id);
      if (thread) await database.collection(COLLECTION.threads).doc(id).set(thread);
    }
    for (const id of dirty.community_posts) {
      const post = state.communityPosts.get(id);
      if (post) await database.collection(COLLECTION.community_posts).doc(id).set(post);
    }
    if (dirty.likes) {
      await database.collection(COLLECTION.likes_state).doc(LIKES_DOC_ID).set(serializeLikesState(state));
    }
    if (dirty.meta) {
      await database.collection(COLLECTION.meta).doc("counters").set(state.counters);
    }
    if (state.devices) {
      for (const token of dirty.devices || []) {
        const device = state.devices.get(token);
        if (device) {
          await database.collection(COLLECTION.devices).doc(token).set({ ...device, token });
        }
      }
    }
  } catch (error) {
    console.error("persistence flush failed", error);
  }
}

function markActivity(dirty, activity) {
  if (activity?.id) dirty.activities.add(activity.id);
}

function markThread(dirty, thread) {
  if (thread?.id) dirty.threads.add(thread.id);
}

function persistenceMiddleware(state, getDirty) {
  return (_req, res, next) => {
    res.on("finish", () => {
      const dirty = getDirty();
      void flush(state, dirty);
    });
    next();
  };
}

async function persistCommunityReport(report) {
  const database = getDatabase();
  if (!database) return;
  try {
    await database.collection(COLLECTION.community_reports).doc(report.id).set(report);
  } catch (error) {
    console.error("persistCommunityReport failed", error);
  }
}

module.exports = {
  persistenceMode,
  hydrate,
  persistAll,
  flush,
  createDirtyTracker,
  markActivity,
  markThread,
  persistenceMiddleware,
  persistCommunityReport,
  COLLECTION,
};
