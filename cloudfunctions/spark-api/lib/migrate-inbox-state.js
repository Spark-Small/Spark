/**
 * One-shot staging migrations for messages inbox (ADR-0002).
 * REASONING: CloudBase may retain pre-inbox threads/inbox_state; merge seed gaps on hydrate.
 */

const { buildSeed } = require("./seed-data");
const { defaultInboxActionItems } = require("./messages-helpers");
const { INBOX_DOC_ID } = require("./inbox-state");

const LEGACY_THREAD_IDS = ["th_001"];

function migrateMessagesInboxState(state) {
  const seed = buildSeed();
  const changes = {
    threads: new Set(),
    threadDeletes: [],
    inbox: false,
  };

  if (!state.inboxActionItems?.length) {
    state.inboxActionItems = defaultInboxActionItems(state.activities);
    changes.inbox = true;
  }
  if (!state.dismissedInboxActionIds) {
    state.dismissedInboxActionIds = new Set();
  }

  for (const legacyId of LEGACY_THREAD_IDS) {
    if (state.threads.delete(legacyId)) {
      changes.threadDeletes.push(legacyId);
    }
  }

  for (const [id, thread] of seed.threads.entries()) {
    if (!state.threads.has(id)) {
      state.threads.set(id, thread);
      changes.threads.add(id);
    }
  }

  for (const [peerId, threadId] of Object.entries(seed.inboxState.mutual_matches)) {
    if (!state.mutualMatches.has(peerId)) {
      state.mutualMatches.set(peerId, threadId);
      changes.inbox = true;
    }
  }

  return changes;
}

function hasInboxMigrationWork(changes) {
  return changes.threads.size > 0 || changes.threadDeletes.length > 0 || changes.inbox;
}

async function applyInboxMigration(state, database, { serializeInboxState, collection }) {
  const changes = migrateMessagesInboxState(state);
  if (!hasInboxMigrationWork(changes)) {
    return false;
  }

  for (const id of changes.threadDeletes) {
    try {
      await database.collection(collection.threads).doc(id).remove();
    } catch (error) {
      console.error("migrate-inbox: delete legacy thread failed", id, error);
    }
  }

  for (const id of changes.threads) {
    const thread = state.threads.get(id);
    if (thread) {
      await database.collection(collection.threads).doc(id).set(thread);
    }
  }

  if (changes.inbox) {
    await database
      .collection(collection.inbox_state)
      .doc(INBOX_DOC_ID)
      .set(serializeInboxState(state));
  }

  console.info(
    "migrate-inbox: applied",
    JSON.stringify({
      threadsAdded: [...changes.threads],
      threadsRemoved: changes.threadDeletes,
      inboxUpdated: changes.inbox,
    })
  );
  return true;
}

module.exports = {
  migrateMessagesInboxState,
  applyInboxMigration,
  hasInboxMigrationWork,
};
