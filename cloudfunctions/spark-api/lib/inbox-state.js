/**
 * Messages inbox auxiliary state (mutual matches, action items, viewer profiles).
 * Persisted in `spark_inbox_state` (replaces legacy `spark_likes_state`).
 */

const INBOX_DOC_ID = "global";

function serializeInboxState(state) {
  return {
    _id: INBOX_DOC_ID,
    viewer_profiles: Object.fromEntries(state.viewerProfiles || new Map()),
    mutual_matches: Object.fromEntries(state.mutualMatches || new Map()),
    inbox_action_items: state.inboxActionItems || [],
    dismissed_inbox_action_ids: [...(state.dismissedInboxActionIds || new Set())],
  };
}

function applyInboxDoc(state, doc) {
  if (!doc) return;
  state.viewerProfiles = new Map(Object.entries(doc.viewer_profiles || {}));
  state.mutualMatches = new Map(Object.entries(doc.mutual_matches || {}));
  if (Array.isArray(doc.inbox_action_items)) {
    state.inboxActionItems = doc.inbox_action_items;
  }
  if (Array.isArray(doc.dismissed_inbox_action_ids)) {
    state.dismissedInboxActionIds = new Set(doc.dismissed_inbox_action_ids);
  } else if (!state.dismissedInboxActionIds) {
    state.dismissedInboxActionIds = new Set();
  }
}

module.exports = {
  INBOX_DOC_ID,
  serializeInboxState,
  applyInboxDoc,
};
