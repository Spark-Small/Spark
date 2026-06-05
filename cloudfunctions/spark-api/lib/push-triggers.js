/**
 * MODULE-B.4 — fire-and-forget push on business events.
 */

const { sendPushToUser } = require("./apns");

function notifyUser(devicesMap, userId, type, payload = {}) {
  if (!userId) return;
  void sendPushToUser(devicesMap, userId, type, payload).catch((error) => {
    console.error(`push ${type} → ${userId} failed`, error);
  });
}

function attendeeUserIds(activity, { excludeUserId } = {}) {
  const ids = [];
  for (const attendee of activity.attendees || []) {
    if (attendee.is_host) continue;
    if (excludeUserId && attendee.id === excludeUserId) continue;
    if (attendee.rsvp_status !== "going" && attendee.rsvp_status !== "maybe") continue;
    if (attendee.id) ids.push(attendee.id);
  }
  return ids;
}

function notifyActivityAttendees(devicesMap, activity, type, payload, excludeUserId) {
  const base = { activity_id: activity.id, title: activity.title, ...payload };
  for (const userId of attendeeUserIds(activity, { excludeUserId })) {
    notifyUser(devicesMap, userId, type, base);
  }
}

function peerUserIdForDirectThread(threadId, senderUserId) {
  if (!threadId.startsWith("th_dm_")) return null;
  const peerId = threadId.slice("th_dm_".length);
  return peerId && peerId !== senderUserId ? peerId : null;
}

module.exports = {
  notifyUser,
  notifyActivityAttendees,
  peerUserIdForDirectThread,
};
