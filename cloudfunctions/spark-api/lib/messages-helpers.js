/**
 * Messages inbox serialization for staging API (docs/API_CONTRACT.md).
 */

function peerUserIdFromDirectThread(threadId) {
  if (!threadId || !threadId.startsWith("th_dm_")) return null;
  return threadId.slice("th_dm_".length);
}

function userProfileFor(state, userId) {
  const profile = state.viewerProfiles?.get?.(userId);
  const displayName = profile?.display_name || displayNameFromMap(userId);
  return {
    display_name: displayName,
    avatar_url: profile?.avatar_url || `https://picsum.photos/seed/${userId}/96/96`,
  };
}

function activityForThread(state, threadId) {
  for (const activity of state.activities.values()) {
    if (activity.thread_id === threadId) return activity;
  }
  if (threadId.startsWith("th_activity_")) {
    const activityId = threadId.slice("th_activity_".length);
    return state.activities.get(activityId) || null;
  }
  return null;
}

function serializeActivitySummary(activity) {
  if (!activity) return null;
  return {
    id: activity.id,
    title: activity.title,
    cover_url: activity.cover_url || `https://picsum.photos/seed/${activity.id}/96/96`,
    starts_at: activity.starts_at,
    attendee_count: activity.attendee_count ?? 0,
    lifecycle:
      activity.lifecycle_status === "cancelled" || activity.lifecycle_status === "ended"
        ? "ended"
        : "upcoming",
  };
}

function serializeDmPartner(state, threadId) {
  const peerId = peerUserIdFromDirectThread(threadId);
  if (!peerId) return null;
  const profile = userProfileFor(state, peerId);
  return {
    id: peerId,
    display_name: profile.display_name,
    avatar_url: profile.avatar_url,
    first_name: profile.display_name.slice(0, 1),
  };
}

function displayNameFromMap(userId) {
  const names = {
    u_host_1: "阿乐",
    u_host_2: "小雨",
    u_like_1: "阿乐",
    u_like_2: "小雨",
    u_like_3: "小晨",
    u_staging_1: "Staging User",
  };
  return names[userId] || "Spark User";
}

function serializeThreadConversation(state, thread) {
  const isDm = thread.id.startsWith("th_dm_");
  const activity = activityForThread(state, thread.id);
  const base = {
    id: thread.id,
    kind: isDm ? "dm" : "group_chat",
    display_name: thread.peer_display_name,
    last_message_preview: thread.last_message_preview || "",
    last_activity_at: thread.last_activity_at,
    unread_count: thread.unread_count ?? 0,
    is_archived: Boolean(thread.is_archived),
  };
  if (isDm) {
    base.dm_partner = serializeDmPartner(state, thread.id);
    base.is_partner_online = thread.is_partner_online ?? false;
  } else {
    const summary = serializeActivitySummary(activity);
    if (summary) base.activity = summary;
    base.member_count = activity?.attendee_count ?? thread.member_count ?? 0;
  }
  return base;
}

function buildActionItems(state) {
  const dismissed = state.dismissedInboxActionIds || new Set();
  const items = state.inboxActionItems || [];
  return items.filter((item) => !dismissed.has(item.id));
}

function buildUnmessagedMatches(state) {
  const matches = [];
  const mutual = state.mutualMatches || new Map();
  for (const [peerId, threadId] of mutual.entries()) {
    const thread = state.threads.get(threadId);
    const hasConversation =
      thread &&
      ((thread.last_message_preview || "").trim().length > 0 ||
        (thread.messages || []).some((m) => (m.body || "").trim().length > 0));
    if (hasConversation) continue;

    const profile = userProfileFor(state, peerId);
    matches.push({
      id: `match_${peerId}`,
      user: {
        id: peerId,
        display_name: profile.display_name,
        avatar_url: profile.avatar_url,
        first_name: profile.display_name.slice(0, 1),
      },
      matched_at: thread?.last_activity_at || new Date().toISOString(),
      thread_id: threadId,
    });
  }
  return matches;
}

function buildInboxResponse(state) {
  const dmConversations = [];
  const groupConversations = [];

  for (const thread of state.threads.values()) {
    const conversation = serializeThreadConversation(state, thread);
    if (conversation.kind === "dm") {
      dmConversations.push(conversation);
    } else if (conversation.is_archived) {
      groupConversations.push(conversation);
    } else {
      groupConversations.push(conversation);
    }
  }

  dmConversations.sort((a, b) => Date.parse(b.last_activity_at) - Date.parse(a.last_activity_at));
  groupConversations.sort((a, b) => {
    const left = Date.parse(a.activity?.starts_at || a.last_activity_at);
    const right = Date.parse(b.activity?.starts_at || b.last_activity_at);
    return left - right;
  });

  return {
    action_items: buildActionItems(state),
    unmessaged_matches: buildUnmessagedMatches(state),
    dm_conversations: dmConversations,
    group_conversations: groupConversations,
  };
}

function buildConversationContext(state, threadId) {
  if (!threadId.startsWith("th_dm_")) {
    return { shared_activities: [], relationship_status: "none" };
  }

  const shared = [];
  for (const activity of state.activities.values()) {
    const attendees = activity.attendees || [];
    const peerId = peerUserIdFromDirectThread(threadId);
    const viewerGoing = attendees.some(
      (att) => att.id === "u_staging_1" && ["going", "maybe", "host"].includes(att.rsvp_status)
    );
    const peerGoing = attendees.some(
      (att) => att.id === peerId && ["going", "maybe", "host"].includes(att.rsvp_status)
    );
    if (viewerGoing && peerGoing) {
      const summary = serializeActivitySummary(activity);
      if (summary) shared.push(summary);
    }
  }

  return {
    shared_activities: shared,
    relationship_status: "matched",
  };
}

function dismissActionItemForInvite(state, invitationId) {
  if (!state.dismissedInboxActionIds) {
    state.dismissedInboxActionIds = new Set();
  }
  for (const item of state.inboxActionItems || []) {
    if (item.type === "activity_invite" && item.invite?.id === invitationId) {
      state.dismissedInboxActionIds.add(item.id);
    }
  }
  if (state.dirty) state.dirty.inbox = true;
}

function dismissInboxActionItem(state, actionItemId) {
  const items = state.inboxActionItems || [];
  if (!items.some((item) => item.id === actionItemId)) {
    return false;
  }
  if (!state.dismissedInboxActionIds) {
    state.dismissedInboxActionIds = new Set();
  }
  state.dismissedInboxActionIds.add(actionItemId);
  if (state.dirty) state.dirty.inbox = true;
  return true;
}

function defaultInboxActionItems(activities) {
  const hike = activities.get("act_001");
  const coffee = activities.get("act_002");
  const now = new Date();
  const iso = (offsetMs) => new Date(now.getTime() + offsetMs).toISOString();

  return [
    {
      id: "action_waitlist_1",
      type: "waitlist_promoted",
      priority: 0,
      created_at: iso(-120_000),
      activity: serializeActivitySummary(hike),
    },
    {
      id: "action_change_1",
      type: "activity_changed",
      priority: 1,
      created_at: iso(-600_000),
      change: {
        id: "change_1",
        kind: "rescheduled",
        activity: serializeActivitySummary(coffee),
        host_name: coffee?.host_display_name || "小雨",
        previous_schedule_line: "原定本周五",
      },
    },
    {
      id: "action_invite_1",
      type: "activity_invite",
      priority: 2,
      created_at: iso(-1_800_000),
      invite: {
        id: "inv_act_002",
        activity: serializeActivitySummary(coffee),
        inviter: {
          id: coffee?.host_id || "u_host_2",
          display_name: coffee?.host_display_name || "小雨",
          avatar_url: "https://picsum.photos/seed/u-host-2/96/96",
          first_name: "小",
        },
      },
    },
  ];
}

module.exports = {
  buildInboxResponse,
  buildConversationContext,
  dismissActionItemForInvite,
  dismissInboxActionItem,
  defaultInboxActionItems,
  serializeThreadConversation,
  peerUserIdFromDirectThread,
};
