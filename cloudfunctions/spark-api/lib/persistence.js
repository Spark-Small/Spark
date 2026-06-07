/**
 * CloudBase NoSQL write-through persistence (ADR-0002).
 * REASONING: Maps stay the source of truth per request; flush on response finish.
 */

const { buildSeed } = require("./seed-data");
const { INBOX_DOC_ID, serializeInboxState, applyInboxDoc } = require("./inbox-state");

const COLLECTION = {
  users: "spark_users",
  activities: "spark_activities",
  threads: "spark_threads",
  community_posts: "spark_community_posts",
  inbox_state: "spark_inbox_state",
  devices: "spark_devices",
  community_reports: "spark_community_reports",
  meta: "spark_meta",
};

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
    inbox: false,
    meta: false,
  };
}

function applySeed(state) {
  const seed = buildSeed();
  state.users = seed.users;
  state.activities = seed.activities;
  state.communityPosts = seed.communityPosts;
  state.threads = seed.threads;
  state.viewerProfiles = new Map(Object.entries(seed.inboxState.viewer_profiles || {}));
  state.mutualMatches = new Map(Object.entries(seed.inboxState.mutual_matches || {}));
  const { defaultInboxActionItems } = require("./messages-helpers");
  state.inboxActionItems =
    seed.inboxState.inbox_action_items || defaultInboxActionItems(state.activities);
  state.dismissedInboxActionIds = new Set(seed.inboxState.dismissed_inbox_action_ids || []);
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

async function loadInboxState(database, state) {
  const inboxSnap = await database.collection(COLLECTION.inbox_state).doc(INBOX_DOC_ID).get();
  let doc = inboxSnap.data?.[0];
  if (!doc) {
    const legacySnap = await database.collection("spark_likes_state").doc(INBOX_DOC_ID).get();
    const legacyDoc = legacySnap.data?.[0];
    if (legacyDoc) {
      doc = {
        viewer_profiles: legacyDoc.viewer_profiles,
        mutual_matches: legacyDoc.mutual_matches,
        inbox_action_items: legacyDoc.inbox_action_items,
        dismissed_inbox_action_ids: legacyDoc.dismissed_inbox_action_ids,
      };
    }
  }
  applyInboxDoc(state, doc);
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

    await loadInboxState(database, state);

    const metaSnap = await database.collection(COLLECTION.meta).doc("counters").get();
    const metaDoc = metaSnap.data?.[0];
    if (metaDoc) Object.assign(state.counters, metaDoc);

    if (state.activities.size === 0) {
      applySeed(state);
      await persistAll(state);
      return { mode: "cloudbase", seeded: true };
    }

    const { applyInboxMigration } = require("./migrate-inbox-state");
    const migrated = await applyInboxMigration(state, database, {
      serializeInboxState,
      collection: COLLECTION,
    });
    return { mode: "cloudbase", seeded: false, migrated };
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
  await database.collection(COLLECTION.inbox_state).doc(INBOX_DOC_ID).set(serializeInboxState(state));
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
    if (dirty.inbox) {
      await database
        .collection(COLLECTION.inbox_state)
        .doc(INBOX_DOC_ID)
        .set(serializeInboxState(state));
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
