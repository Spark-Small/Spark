/**
 * Likes domain helpers — daily pool, inbound sort, feed ranking (staging heuristic).
 * Contract: docs/API_CONTRACT.md
 */

const DAILY_POOL_SIZE = 50;
const SPARK_DAILY_LIMIT = 3;

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function normalizeDailyEntry(entry) {
  const key = todayKey();
  if (!entry || entry.date !== key) {
    return { date: key, seen_count: 0, spark_used: 0 };
  }
  return entry;
}

function dailyStatsFor(userId, dailyByUser) {
  const entry = normalizeDailyEntry(dailyByUser.get(userId));
  dailyByUser.set(userId, entry);
  return {
    today_seen_count: entry.seen_count,
    daily_pool_size: DAILY_POOL_SIZE,
    spark_charges_remaining: Math.max(0, SPARK_DAILY_LIMIT - entry.spark_used),
  };
}

function incrementSeen(userId, dailyByUser) {
  const entry = normalizeDailyEntry(dailyByUser.get(userId));
  entry.seen_count += 1;
  dailyByUser.set(userId, entry);
}

function consumeSpark(userId, dailyByUser, intensity) {
  if (intensity !== "spark") return { ok: true };
  const entry = normalizeDailyEntry(dailyByUser.get(userId));
  if (entry.spark_used >= SPARK_DAILY_LIMIT) {
    return { ok: false, code: "spark_limit_reached", message: "Daily spark limit reached" };
  }
  entry.spark_used += 1;
  dailyByUser.set(userId, entry);
  return { ok: true };
}

function passedSetFor(userId, passedByUser, legacyPassed) {
  if (!passedByUser.has(userId)) {
    passedByUser.set(userId, new Set(legacyPassed || []));
  }
  return passedByUser.get(userId);
}

function likedSetFor(userId, likedByMeByUser, legacyLiked) {
  if (!likedByMeByUser.has(userId)) {
    likedByMeByUser.set(userId, new Set(legacyLiked || []));
  }
  return likedByMeByUser.get(userId);
}

function inboundListFor(userId, inboundByUser, legacyInbound) {
  if (!inboundByUser.has(userId)) {
    const seed = legacyInbound?.length ? legacyInbound : [];
    inboundByUser.set(userId, [...seed]);
  }
  return inboundByUser.get(userId);
}

function rewindStateFor(userId, rewindByUser, legacy) {
  const key = todayKey();
  let entry = rewindByUser.get(userId);
  if (!entry || entry.date !== key) {
    entry = {
      date: key,
      used_today: false,
      last_pass_user_id: legacy?.last_pass_user_id ?? null,
    };
    rewindByUser.set(userId, entry);
  }
  return entry;
}

function parseLikeBody(body) {
  const intensity = body?.intensity === "spark" ? "spark" : "like";
  const opener =
    typeof body?.opener === "string" ? body.opener.trim().slice(0, 200) || null : null;
  const liked_question_id =
    typeof body?.liked_question_id === "string" ? body.liked_question_id : null;
  const voice_opener_url =
    typeof body?.voice_opener_url === "string" ? body.voice_opener_url : null;
  return { intensity, opener, liked_question_id, voice_opener_url };
}

function sortInboundItems(items) {
  return [...items].sort((a, b) => {
    const aSpark = a.intensity === "spark";
    const bSpark = b.intensity === "spark";
    if (aSpark !== bSpark) return aSpark ? -1 : 1;
    const aOp = Boolean(a.opener);
    const bOp = Boolean(b.opener);
    if (aOp !== bOp) return aOp ? -1 : 1;
    return new Date(b.liked_at) - new Date(a.liked_at);
  });
}

function rankFeedCards(cards, viewerId, viewerProfiles) {
  const profile = viewerProfiles.get(viewerId) || {};
  const viewerTags = new Set(profile.interest_tags || []);
  return [...cards]
    .map((card, index) => {
      let score = 0;
      if (card.is_daily_pick) score += 1000;
      if (card.rank_score != null) score += Number(card.rank_score) || 0;
      for (const tag of card.interest_tags || []) {
        if (viewerTags.has(tag)) score += 25;
      }
      score -= index * 0.01;
      return { card, score };
    })
    .sort((a, b) => b.score - a.score)
    .map((x) => x.card);
}

function mapsToObject(mapOfSets) {
  const out = {};
  for (const [key, value] of mapOfSets.entries()) {
    out[key] = value instanceof Set ? [...value] : value;
  }
  return out;
}

function mapsFromObjectSets(obj) {
  const map = new Map();
  for (const [key, value] of Object.entries(obj || {})) {
    map.set(key, new Set(Array.isArray(value) ? value : []));
  }
  return map;
}

function mapsFromObjectArrays(obj) {
  const map = new Map();
  for (const [key, value] of Object.entries(obj || {})) {
    map.set(key, Array.isArray(value) ? [...value] : []);
  }
  return map;
}

function mapsFromObjectPlain(obj) {
  const map = new Map();
  for (const [key, value] of Object.entries(obj || {})) {
    map.set(key, value);
  }
  return map;
}

module.exports = {
  DAILY_POOL_SIZE,
  SPARK_DAILY_LIMIT,
  todayKey,
  dailyStatsFor,
  incrementSeen,
  consumeSpark,
  passedSetFor,
  likedSetFor,
  inboundListFor,
  rewindStateFor,
  parseLikeBody,
  sortInboundItems,
  rankFeedCards,
  mapsToObject,
  mapsFromObjectSets,
  mapsFromObjectArrays,
  mapsFromObjectPlain,
};
