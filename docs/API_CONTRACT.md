# Spark API Contract (iOS ↔ Backend)

**Status:** Draft for parallel backend development.  
**Source of truth:** `Live*` types and DTOs under `Packages/` (`SparkAuth`, `SparkMessages`, `SparkActivity`, …).  
**Base URL:** `SPARK_API_BASE_URL` (Debug default `https://mock.spark.local` → iOS uses Mock implementations).

## Conventions

| Item | Rule |
|------|------|
| Version prefix | `/v1/...` |
| Auth | `Authorization: Bearer <access_token>` on protected routes |
| JSON keys | `snake_case` in wire format; Swift DTOs map via `CodingKeys` |
| Dates | ISO-8601 UTC strings, e.g. `2026-06-04T12:00:00Z` |
| Errors | HTTP status + JSON body (see [Error body](#error-body)) |

### Error body

```json
{
  "error": {
    "code": "invalid_credentials",
    "message": "Human-readable message for client"
  }
}
```

iOS maps HTTP status to `AppError` via `HTTPErrorMapper` (`401` → `.unauthorized`, etc.).

---

## Auth

### `GET /v1/auth/session`

Validates/refreshes the current session.

**Headers:** `Authorization: Bearer <token>` (optional if no cached session on client)

**Response `200`:**

```json
{
  "access_token": "eyJ...",
  "user_id": "u_abc123"
}
```

**Response `401`:** No valid session (client clears Keychain).

---

### `POST /v1/auth/email`

**Request:**

```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

**Response `200`:** Same as session response.

**Response `401`:** Invalid credentials → iOS `AuthError.invalidCredentials`.

---

### `POST /v1/auth/apple`

**Request:**

```json
{
  "identity_token": "<base64>",
  "authorization_code": "<base64 or null>"
}
```

**Response `200`:** Same as session response.

---

### `POST /v1/auth/sign-out`

**Headers:** `Authorization: Bearer <token>`

**Response `204`:** Empty body. Client clears local session regardless of network failure after best effort.

---

## Messages

### `GET /v1/messages/unread-count`

**Response `200`:**

```json
{
  "count": 3
}
```

---

### `POST /v1/messages/read`

Marks all threads read for the current user.

**Response `204`:** Empty body.

---

### `POST /v1/messages/threads/{thread_id}/read`

Marks one thread read for the current user (inbox swipe / open conversation).

**Path:** `thread_id` — opaque thread identifier.

**Response `204`:** Empty body.

**Response `404`:** Thread not found.

---

### `GET /v1/messages/inbox`

Unified inbox for the messages tab (action items, new matches, DM and group conversations).

**Response `200`:**

```json
{
  "action_items": [
    {
      "id": "action_1",
      "type": "activity_invite",
      "priority": 2,
      "created_at": "2026-06-04T08:00:00Z",
      "invite": {
        "id": "inv_1",
        "activity": {
          "id": "act_2",
          "title": "周末爬香山",
          "starts_at": "2026-06-07T09:00:00Z",
          "attendee_count": 12
        },
        "inviter": {
          "id": "u_wang",
          "display_name": "王芳"
        }
      }
    }
  ],
  "unmessaged_matches": [
    {
      "id": "match_1",
      "user": { "id": "u_li", "display_name": "李明" },
      "matched_at": "2026-06-04T07:00:00Z"
    }
  ],
  "dm_conversations": [
    {
      "id": "th_dm_u_ale",
      "kind": "dm",
      "display_name": "阿乐",
      "last_message_preview": "周六一起爬山吗？",
      "last_message_at": "2026-06-04T10:00:00Z",
      "unread_count": 1
    }
  ],
  "group_conversations": [
    {
      "id": "th_activity_act_1",
      "kind": "group_chat",
      "display_name": "周末徒步 · 群",
      "last_message_preview": "周六 9:30 北门集合",
      "last_message_at": "2026-06-04T09:30:00Z",
      "unread_count": 0,
      "is_archived": false
    }
  ]
}
```

`action_items[].type`: `activity_invite` | `activity_changed` | `waitlist_promoted`.

`group_conversations` with `is_archived: true` render in the archived disclosure.

**Fallback:** iOS `LiveMessagesRepository` derives a minimal inbox from `GET /v1/messages/threads` when this endpoint returns `404`.

---

### `POST /v1/messages/inbox/action-items/{action_item_id}/dismiss`

Dismiss a non-invite action card (`activity_changed`, `waitlist_promoted`) or manually clear any action item from the inbox. Invite cards are removed via `POST /v1/activities/{activity_id}/invitations/{invitation_id}/respond`.

**Response `204`:** Empty body.

**Errors:** `404 not_found` when `action_item_id` is unknown.

---

### `GET /v1/messages/threads/{thread_id}/context`

DM / thread metadata for conversation detail header.

**Response `200`:**

```json
{
  "shared_activities": [
    {
      "id": "act_1",
      "title": "周末爬香山",
      "starts_at": "2026-06-07T09:00:00Z",
      "attendee_count": 12
    }
  ],
  "relationship_status": "matched"
}
```

---

### `GET /v1/messages/threads`

Inbox list for the messages tab.

**Response `200`:**

```json
{
  "threads": [
    {
      "id": "th_001",
      "peer_display_name": "阿乐",
      "last_message_preview": "活动现场见！",
      "last_activity_at": "2026-06-04T10:30:00Z",
      "unread_count": 1
    }
  ]
}
```

---

### `GET /v1/messages/threads/{thread_id}/messages`

**Path:** `thread_id` — opaque thread identifier.

**Response `200`:**

```json
{
  "messages": [
    {
      "id": "msg_001",
      "thread_id": "th_001",
      "body": "你好！",
      "sent_at": "2026-06-04T09:00:00Z",
      "is_from_current_user": false
    }
  ]
}
```

Ordered ascending by `sent_at` (oldest first) for chat UI.

---

### `POST /v1/messages/threads/{thread_id}/messages`

Send a message (optional for MVP backend; iOS Mock implements locally).

**Request:**

```json
{
  "body": "Hello"
}
```

**Response `201`:**

```json
{
  "id": "msg_002",
  "thread_id": "th_001",
  "body": "Hello",
  "sent_at": "2026-06-04T10:31:00Z",
  "is_from_current_user": true
}
```

---

## Activities

### `GET /v1/activities/feed`

Signed-in user's activity feed for the Activity tab (`SparkActivity` → `LiveActivityFeedRepository`).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Response `200`:**

```json
{
  "items": [
    {
      "id": "act_001",
      "title": "周末徒步",
      "summary": "城郊步道 · 周六上午",
      "category": "活动",
      "starts_at": "2026-06-07T09:30:00Z",
      "location_name": "城郊步道北门",
      "host_display_name": "阿乐",
      "attendee_count": 5,
      "capacity": 8,
      "rsvp_status": "going",
      "thread_id": "th_001"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `items` | array | Yes | May be `[]` when the user has no activities |
| `items[].id` | string | Yes | Stable activity id (opaque) |
| `items[].title` | string | Yes | Display title |
| `items[].summary` | string | Yes | Legacy short hint; used when `starts_at` omitted |
| `items[].category` | string | Yes | Label shown above title (e.g. 活动, 社交, 运动) |
| `items[].starts_at` | string | No | ISO-8601 start time (invitation apps) |
| `items[].location_name` | string | No | Venue / meeting point (display only, not raw GPS) |
| `items[].host_display_name` | string | No | Organizer label |
| `items[].attendee_count` | integer | No | Current RSVP count, default `0` |
| `items[].capacity` | integer | No | Max attendees; omit when unlimited |
| `items[].rsvp_status` | string | No | `invited` · `going` · `maybe` · `declined` · `host` |
| `items[].lifecycle_status` | string | No | `scheduled` · `cancelled` · `ended`; default `scheduled` |
| `items[].thread_id` | string | No | Activity group chat thread |

**Response `401`:** Invalid or expired token (client clears session).

**Response `5xx`:** Standard [error body](#error-body); iOS shows retry on the Activity tab.

**Backend notes**

- Sort order: server-defined (e.g. `starts_at` desc); iOS renders list order as returned.
- `thread_id` convention: `th_activity_{activity_id}`; provision via `POST /v1/messages/activity-threads` when user signs up (`going` / `maybe`).
- Pagination: not required for MVP; add `cursor` later without breaking this shape.

### `GET /v1/activities/browse`

**Status:** **Backend + iOS shipped** (`spark-api` MODULE-A.2, `SparkActivity` MODULE-D). Entry: Activity Tab toolbar「逛局」— [ADR-0003](adr/0003-activities-browse-placement.md).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Query:**

| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `category` | string | No | Exact match on `items[].category` |
| `starts_after` | ISO8601 | No | Inclusive lower bound on `starts_at` |
| `starts_before` | ISO8601 | No | Inclusive upper bound on `starts_at` |
| `cursor` | string | No | Activity `id` for next page |

**Response `200`:** Same item shape as [feed](#get-v1activitiesfeed); excludes `cancelled` / `ended`; sorted by `starts_at` ascending; page size 20.

```json
{
  "items": [ { "id": "act_001", "title": "周末徒步", "summary": "…", "category": "活动", "starts_at": "…", "lifecycle_status": "scheduled" } ],
  "next_cursor": "act_002"
}
```

**人发现** remains [Likes](#likes-social-discovery) (`GET /v1/likes/feed`) — not this path.

### `GET /v1/activities/{activity_id}`

Invitation detail for the Activity tab (`SparkActivity` → `LiveActivityFeedRepository.fetchActivity`).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Response `200`:**

```json
{
  "activity": {
    "id": "act_001",
    "title": "周末徒步",
    "summary": "城郊步道 · 周六上午",
    "category": "活动",
    "description": "集合后统一出发，自备饮水。",
    "starts_at": "2026-06-07T09:30:00Z",
    "location_name": "城郊步道北门",
    "host_display_name": "阿乐",
    "attendee_count": 5,
    "capacity": 8,
    "rsvp_status": "going",
    "thread_id": "th_001"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `activity.description` | string | Yes | Full invitation copy |
| `activity.lifecycle_status` | string | No | Same as feed |
| `activity.attendees` | array | No | `[{ "id", "display_name", "is_host" }]` preview for registrants |
| Other fields | | | Same semantics as feed item |

**Response `404`:** Unknown activity.

---

### `POST /v1/activities/{activity_id}/rsvp`

Submit or update the current user's RSVP (`UpdateActivityRSVPUseCase`).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Request:**

```json
{
  "status": "going"
}
```

Allowed `status`: `going` · `maybe` · `declined` (not `host` / `invited`).

**Response `200`:** Same shape as `GET /v1/activities/{activity_id}` (`activity` object with updated `rsvp_status` / counts).

**Backend:** On `going` / `maybe`, add user to activity group thread and return `thread_id`.

---

### `POST /v1/activities/{activity_id}/invitations/{invitation_id}/respond`

Swift Live path literal: `/v1/activities/\(activityID)/invitations/\(invitationID)/respond`

Respond to an activity invitation from the messages inbox action card.

**Request:**

```json
{
  "response": "accept"
}
```

Allowed `response`: `accept` · `decline`.

**Response `204`:** Empty body.

---

### `POST /v1/activities`

Host creates a new activity (`CreateActivityUseCase`).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Request:**

```json
{
  "title": "周末徒步",
  "description": "集合后统一出发。",
  "location_name": "城郊步道北门",
  "starts_at": "2026-06-07T09:30:00Z",
  "capacity": 8
}
```

**Response `201`:** Same body as `GET /v1/activities/{activity_id}` with `rsvp_status: "host"` and `thread_id` set.

---

### `PATCH /v1/activities/{activity_id}`

Host updates a scheduled activity. Request body matches create. Response `200`: updated `activity`.

---

### `POST /v1/activities/{activity_id}/cancel`

Host cancels the activity (`lifecycle_status: cancelled`). Response `200`: updated `activity`.

---

### `POST /v1/activities/{activity_id}/report`

Registrant reports an activity. Request: `{ "reason": "spam" | "inappropriate" | "safety" | "other" }`.

**Response `200`:**

```json
{
  "report_id": "rpt_abc123"
}
```

---

### `GET /v1/activities/feed` (host filter, Phase 20)

**Query (optional):** `host_id` — other activities by the same host (detail “更多活动”).

**Detail / feed extensions (Phase 20–21):** `host_id` · `host_bio` · `waitlisted_count` · `attendees[].verified` · `rsvp_status: waitlisted`.

---

### `POST /v1/activities/{activity_id}/waitlist` (Phase 21)

Join waitlist when at capacity. Response `200`: `activity` with `rsvp_status: "waitlisted"`.

### `POST /v1/activities/{activity_id}/waitlist/{attendee_id}/promote` (Phase 21)

Host promotes a waitlisted attendee to `going`. Response `200`: updated `activity`.

---

### `POST /v1/activities/{activity_id}/announce` (Phase 22)

Host broadcast to activity group. Request: `{ "message": "…" }`. Response `204`. Server should mirror message into `thread_id`.

---

### `POST /v1/activities/{activity_id}/feedback` (Phase 24)

Post-event host feedback. Request: `{ "feedback": "positive" | "negative" }`. Response `204`.

---

### Activity API path literals (iOS Live)

| Method | Path |
|--------|------|
| GET | `/v1/activities/feed` |
| POST | `/v1/activities` |
| GET | `/v1/activities/{activity_id}` |
| PATCH | `/v1/activities/{activity_id}` |
| POST | `/v1/activities/{activity_id}/rsvp` |
| POST | `/v1/activities/{activity_id}/waitlist` |
| POST | `/v1/activities/{activity_id}/waitlist/{attendee_id}/promote` |
| POST | `/v1/activities/{activity_id}/cancel` |
| POST | `/v1/activities/{activity_id}/report` |
| POST | `/v1/activities/{activity_id}/announce` |
| POST | `/v1/activities/{activity_id}/feedback` |

**Deep links (iOS):** `spark://activity/{activity_id}` · `https://spark.app/a/{activity_id}` · `spark://community?activity_id={id}` (recap draft)

### `POST /v1/devices` (Phase 16)

Register APNs device token after user grants notification permission.

**Headers:** `Authorization: Bearer <access_token>` (required)

**Request:**

```json
{
  "token": "<hex_apns_device_token>",
  "platform": "ios"
}
```

**Response `204`:** Token stored in `spark_devices` for activity push (`activity.reminder`, `activity.cancelled`, `activity.updated`).

### `POST /v1/notifications/send` (MODULE-B, internal)

Deliver push via APNs HTTP/2 when `APNS_*` env vars are set on the cloud function; otherwise returns `202` queued stub.

**Request:** `{ "user_id": "...", "type": "likes.match", "payload": { "thread_id": "..." } }`

**Response `200` (APNs configured, devices found):** `{ "queued": false, "apns_configured": true, "sent", "failed", "errors" }`

**Response `202` (stub or no devices):** `{ "queued": true, "apns_configured": false|true, "user_id", "type", "payload" }`

**Cloud function env:** `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY` (`.p8` PEM), `APNS_BUNDLE_ID`, optional `APNS_USE_SANDBOX` (default sandbox).

---

### `POST /v1/messages/activity-threads`

Idempotent: join or create the activity group thread after signup (`ensureActivityGroupThread`).

**Request:**

```json
{
  "thread_id": "th_activity_act_002",
  "display_name": "咖啡聊天局 · 群",
  "welcome_message": "欢迎加入「咖啡聊天局」活动群…"
}
```

**Response `204`:** Thread ready; inbox lists `display_name` as peer label.

---

### `POST /v1/messages/direct-threads`

Creates or returns a 1:1 thread after mutual like (`ensureDirectMessageThread`).

**Request:**

```json
{
  "peer_user_id": "u_like_2",
  "peer_display_name": "小雨"
}
```

**Response `200`:**

```json
{
  "thread_id": "th_dm_u_like_2"
}
```

---

### Messages API path literals (iOS Live)

Documented for `MessagesAPIPath` in `SparkMessages`:

| Method | Path |
|--------|------|
| GET | `/v1/messages/unread-count` |
| GET | `/v1/messages/inbox` |
| POST | `/v1/messages/inbox/action-items/{action_item_id}/dismiss` |
| POST | `/v1/messages/inbox/action-items/\(id)/dismiss` (iOS `MessagesAPIPath.dismissActionItem`) |
| GET | `/v1/messages/threads` |
| GET | `/v1/messages/threads/{thread_id}/context` |
| POST | `/v1/messages/read` |
| POST | `/v1/messages/threads/{thread_id}/read` |
| POST | `/v1/messages/activity-threads` |
| POST | `/v1/messages/direct-threads` |
| GET/POST | `/v1/messages/threads/{thread_id}/messages` (built as `threads` + `/{id}/messages`) |

---

## Search

### `GET /v1/search?q={query}`

Full-text search for the Search tab (`SparkSearch` → `LiveSearchRepository`).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Query**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | Yes | User query; URL-encoded |

**Response `200`:**

```json
{
  "results": [
    {
      "id": "sr_001",
      "title": "周末徒步",
      "subtitle": "活动 · 周六",
      "kind": "activity"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `results` | array | Yes | May be `[]` |
| `results[].id` | string | Yes | Stable result id |
| `results[].title` | string | Yes | Primary label |
| `results[].subtitle` | string | Yes | Secondary line |
| `results[].kind` | string | Yes | Category chip (e.g. `activity`, `community`, `person`) |

**Response `401`:** Invalid or expired token.

### Search API path literals (iOS Live)

| Method | Path |
|--------|------|
| GET | `/v1/search?q={query}` (built in `SearchAPIPath`) |

---

## Community

### `GET /v1/community/feed`

Tab experience for the Community discover screen (`SparkCommunity` → `LiveCommunityPostsRepository.fetchTabExperience`).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Response `200`:**

```json
{
  "joined_communities": [
    {
      "id": "cm_hike",
      "name": "爬山队",
      "cover_url": "https://example.com/cover.jpg",
      "member_count": 38,
      "activity_count": 12,
      "has_new_posts": true,
      "bio": ""
    }
  ],
  "items": [
    { "type": "post", "post": { "id": "cp_001", "author_display_name": "阿乐" } },
    { "type": "people_discovery", "people": [{ "id": "u_like_1", "display_name": "李明" }] }
  ],
  "all_communities": []
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `joined_communities` | array | Yes | User's joined groups |
| `items` | array | Yes | Mixed feed (`post` \| `people_discovery`) |
| `all_communities` | array | Yes | Discoverable communities |

**Fallback:** iOS Live repo derives a minimal tab from `GET /v1/community/posts` when feed returns `404`.

### `GET /v1/community/communities/{community_id}`

Community detail header (`LiveCommunityPostsRepository.fetchCommunityDetail`).

**Response `200`:** `{ "community": { "id", "name", "cover_url", "member_count", "activity_count", "has_new_posts", "bio", "is_joined" } }`

### `GET /v1/community/communities/{community_id}/activities`

Linked activities for community detail activities tab.

**Response `200`:** `{ "activities": [{ "id", "title", "schedule_line" }] }`

### `GET /v1/community/communities/{community_id}/members`

Members with relationship context.

**Response `200`:** `{ "members": [{ "id", "display_name", "avatar_url", "bio", "relationship_to_viewer" }] }`

### `GET /v1/community/posts`

Community discussion list for the Community tab (`SparkCommunity` → `LiveCommunityPostsRepository`).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Response `200`:**

```json
{
  "posts": [
    {
      "id": "cp_001",
      "title": "周末去哪玩？",
      "excerpt": "城郊徒步局还差两人",
      "author_display_name": "阿乐",
      "reply_count": 12
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `posts` | array | Yes | May be `[]` |
| `posts[].id` | string | Yes | Post id |
| `posts[].title` | string | Yes | Headline |
| `posts[].excerpt` | string | Yes | Preview text |
| `posts[].author_display_name` | string | Yes | Author label |
| `posts[].reply_count` | integer | Yes | Reply count ≥ 0 |

**Response `401`:** Invalid or expired token.

### `GET /v1/community/posts/{post_id}`

Single post for the Community detail screen (`SparkCommunity` → `LiveCommunityPostsRepository.fetchPost`).

**Headers:** `Authorization: Bearer <access_token>` (required)

**Response `200`:**

```json
{
  "post": {
    "id": "cp_001",
    "title": "周末去哪玩？",
    "body": "城郊步道周六上午集合，还差两人。",
    "author_display_name": "阿乐",
    "reply_count": 12,
    "replies": [
      {
        "id": "cpr_001",
        "body": "周六可以，几点集合？",
        "author_display_name": "小雨",
        "created_at": "2026-06-01T10:00:00.000Z"
      }
    ]
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `post.id` | string | Yes | Same id as list item |
| `post.title` | string | Yes | Headline |
| `post.body` | string | Yes | Full post text |
| `post.author_display_name` | string | Yes | Author label |
| `post.reply_count` | integer | Yes | Reply count ≥ 0 |
| `post.replies` | array | No | Thread replies (may be `[]`) |
| `post.replies[].id` | string | Yes | Reply id |
| `post.replies[].body` | string | Yes | Reply text |
| `post.replies[].author_display_name` | string | Yes | Author label |
| `post.replies[].created_at` | string (ISO8601) | No | Created timestamp |

**Response `404`:** Unknown post id.

### `POST /v1/community/posts` (MODULE-E)

Create a text post (Staging: no moderation queue).

**Request:** `{ "title": "...", "body": "..." }`

**Response `201`:** `{ "post": { "id", "title", "excerpt", "author_display_name", "reply_count" } }` (list item shape).

### `POST /v1/community/posts/{post_id}/replies` (MODULE-E.2)

Add a text reply to a post thread.

**Request:** `{ "body": "..." }`

**Response `201`:** `{ "reply": { "id", "body", "author_display_name", "created_at" } }`

**Response `404`:** Unknown post id.

### `POST /v1/community/posts/{post_id}/report` (MODULE-E.4)

**Request:** `{ "reason": "spam" }` (optional, max 500 chars)

**Response `201`:** `{ "report_id": "cprpt_001", "status": "pending" }` — persisted to `spark_community_reports`.

### Community API path literals (iOS Live)

| Method | Path |
|--------|------|
| GET | `/v1/community/posts` |
| POST | `/v1/community/posts` |
| GET | `/v1/community/posts/{post_id}` (built in `CommunityAPIPath.post`) |
| POST | `/v1/community/posts/{post_id}/replies` (built in `CommunityAPIPath.replies`) |
| POST | `/v1/community/posts/{post_id}/report` |

**Deep links (iOS):** `spark://community/post/{post_id}` · `spark://community?post_id={id}`

---

## Likes (social discovery)

**Module:** `SparkLikes` · **Tab:** 喜欢 · **ADR:** [adr/0001-likes-tab-social-discovery.md](adr/0001-likes-tab-social-discovery.md)

Vertical discover feed (image/video cards). User actions: **like**, **pass**, **friend_request**. Mutual like → **match** → direct message thread.

### `GET /v1/likes/feed`

**Query:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `cursor` | string | No | Opaque pagination cursor |
| `gender_pref` | string | No | `all` · `same` · `opposite` (client preference) |
| `intent` | string | No | `friends` · `match` |

**Response `200`:**

```json
{
  "items": [
    {
      "user_id": "u_like_2",
      "display_name": "小雨",
      "bio": "咖啡、聊天、慢生活",
      "gender": "female",
      "media": {
        "kind": "image",
        "url": "https://cdn.example/like/u2.jpg",
        "poster_url": null
      }
    }
  ],
  "next_cursor": "c_abc"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `items[].user_id` | string | Yes | Discoverable user |
| `items[].display_name` | string | Yes | Card title |
| `items[].bio` | string | No | One-line subtitle |
| `items[].gender` | string | No | `male` · `female` · `other` — display/filter only |
| `items[].media.kind` | string | Yes | `image` · `video` |
| `items[].media.url` | string | Yes | Asset URL |
| `items[].media.poster_url` | string | No | Video poster |

**Response `204`:** No more cards (client shows empty state).

---

### `POST /v1/likes/{user_id}/like`

**Request (optional JSON body):**

```json
{
  "intensity": "spark",
  "opener": "你的笑容很治愈",
  "liked_question_id": "sq_1"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `intensity` | string | No | `like` (default) · `spark` (super-like / 心动) |
| `opener` | string | No | Compliment attached to the like (shown on inbound) |
| `liked_question_id` | string | No | Spark question the viewer liked from profile |
| `voice_opener_url` | string | No | Optional voice memo URL when voice icebreaker is supported (no client stub until upload ships) |

**Response `200`:**

```json
{
  "outcome": "matched",
  "thread_id": "th_dm_u_like_2"
}
```

| `outcome` | Meaning |
|-----------|---------|
| `matched` | Mutual like; open DM (`thread_id` set) |
| `pending` | Recorded; wait for peer |
| `already_connected` | Existing thread; `thread_id` may be set |

---

### `POST /v1/likes/{user_id}/pass`

**Response `204`:** Card removed from future feed for this user pair.

---

### `POST /v1/likes/{user_id}/friend-request`

Non-match friend path (e.g. platonic same-gender).

**Response `200`:**

```json
{
  "outcome": "sent"
}
```

**Response `409`:** Already friends or request pending (`error.code`: `already_connected`).

---

### `POST /v1/likes/{user_id}/report`

**Request:**

```json
{
  "reason": "spam",
  "detail": "optional text"
}
```

**Response `200`:** `{ "report_id": "rp_xxx" }`

---

### `POST /v1/likes/{user_id}/block`

**Response `204`:** User hidden from feed.

---

### `GET /v1/likes/inbound`

Users who liked the viewer (not yet matched / passed).

**Query:** `cursor` (optional)

**Response `200`:**

```json
{
  "items": [
    {
      "user_id": "u_like_5",
      "liked_at": "2026-06-05T12:00:00Z",
      "is_visible": false,
      "card": { }
    }
  ],
  "next_cursor": null
}
```

`card` uses the same shape as [feed items](#get-v1likesfeed).

| Field | Type | Description |
|-------|------|-------------|
| `items[].is_visible` | boolean | `false` when viewer lacks premium inbound entitlement (ADR-0004) |
| `items[].intensity` | string | No | `like` · `spark` — spark likes sort first in client |
| `items[].opener` | string | No | Compliment from liker |
| `items[].liked_question_id` | string | No | Question ID if liker praised a spark answer |

---

### `GET /v1/likes/daily-stats`

Daily discover pool progress and spark allowance.

**Response `200`:**

```json
{
  "today_seen_count": 12,
  "daily_pool_size": 50,
  "spark_charges_remaining": 2
}
```

---

### `POST /v1/likes/rewind`

Undo the most recent pass (client: once per calendar day recommended).

**Response `200`:** `{ "card": { ... } }` or `{ "card": null }` if unavailable.

---

### `GET /v1/likes/viewer-profile`

Minimum profile for discover gate (like/pass requires `has_photo` + non-empty `display_name`).

**Response `200`:** `{ "display_name": "...", "has_photo": true, "avatar_url": "https://..." }` (`avatar_url` optional)

### `PATCH /v1/likes/viewer-profile`

**Request:** `{ "display_name": "...", "has_photo": true, "avatar_url": "https://...", "is_premium": true }`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `is_premium` | boolean | No | Synced from StoreKit after purchase / restore / refund (MODULE-G); drives `inbound[].is_visible` |

**Response `200`:** Updated profile (same shape as GET).

### `POST /v1/users/avatar/upload-url` (MODULE-F)

Staging returns `upload_url: null` and a ready `avatar_url` (no client upload). When `upload_url` is non-null, iOS `PUT`s JPEG bytes (≤ 1 MB) before `PATCH` profile with `avatar_url`.

**Request:** `{ "content_type": "image/jpeg" }`

**Response `200`:** `{ "upload_url": null, "avatar_url": "...", "expires_at": "ISO8601" }`

### `PATCH /v1/users/profile`

Alias for profile fields including `avatar_url` (same semantics as `PATCH /v1/likes/viewer-profile`).

### Push payloads (APNs)

| `type` | Action |
|--------|--------|
| `likes.inbound` | Open inbound list (`spark://likes/inbound`) |
| `likes.match` | Open DM when `thread_id` set; else inbound |
| `messages.new` | Open thread (`thread_id`) |
| `activity.updated` / `activity.cancelled` | Open activity detail (`activity_id`) |
| `community.reply` | Open community post (`post_id`) |

**MODULE-B.4 triggers (server):** like → `likes.inbound` / `likes.match`; DM message → `messages.new`; host patch/cancel/announce → `activity.*`; reply → `community.reply`.

---

### Likes API path literals (iOS Live)

| Method | Path |
|--------|------|
| GET | `/v1/likes/feed` |
| GET | `/v1/likes/inbound` |
| GET | `/v1/likes/viewer-profile` |
| PATCH | `/v1/likes/viewer-profile` |
| POST | `/v1/likes/rewind` |
| POST | `/v1/likes/{user_id}/like` |
| POST | `/v1/likes/{user_id}/pass` |
| POST | `/v1/likes/{user_id}/friend-request` |
| POST | `/v1/likes/{user_id}/report` |
| POST | `/v1/likes/{user_id}/block` |
| GET | `/v1/likes/daily-stats` |

**Deep links (iOS):** `spark://likes` · `spark://likes/inbound` · Universal `https://spark.app/tab/likes` · `https://spark.app/tab/likes/inbound`

**Feed item extensions (optional):** `media_items[]`, `interest_tags[]`, `coarse_location`, `shared_activity: { activity_id, title }`, `spark_questions[]: { id, question, answer }`, `is_daily_pick` (boolean)

---

## Environment matrix

| Environment | `SPARK_API_BASE_URL` | iOS data layer | Backend |
|-------------|----------------------|----------------|---------|
| Local / no backend | `https://mock.spark.local` | `Mock*` repositories | None |
| Staging (CloudBase MVP) | `https://ais-d1gab0emob99361a0.service.tcloudbase.com` | `Live*` types | HTTP 云函数 `spark-api` — CloudBase NoSQL write-through ([ADR-0002](adr/0002-backend-persistence-cloudbase-nosql.md)); `SPARK_PERSISTENCE=memory` for local |
| Staging (team host) | `https://api.staging.spark.app` | `Live*` types | Team backend |
| Production | `https://api.spark.app` | `Live*` types | Production API |

Copy `Config/Secrets.xcconfig.example` → `Config/Secrets.xcconfig` (gitignored) to override the base URL without editing shared xcconfig.

### Staging MVP coverage (`spark-api`)

| Area | iOS Live paths | MVP status |
|------|----------------|------------|
| Auth | email · session · apple · sign-out | Implemented |
| Messages | unread · threads · messages · read · activity/direct threads | Implemented |
| Activities | feed · browse · detail · create · patch · rsvp · waitlist · promote · cancel · report · announce · feedback | Implemented (NoSQL write-through) |
| Search · Community · Likes · devices | per path tables above | Implemented |
| `GET /v1/activities/browse` | `LiveActivityBrowseRepository` (MODULE-D) | Backend implemented |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-04 | Initial contract: auth + messages threads/messages |
| 2026-06-04 | Add activities feed |
| 2026-06-04 | Activity `thread_id`; document Messages Live path literals |
| 2026-06-05 | Search `GET /v1/search`; Community `GET /v1/community/posts` |
| 2026-06-05 | Community post detail `GET /v1/community/posts/{post_id}` |
| 2026-06-05 | Activity invitation fields, detail + RSVP endpoints |
| 2026-06-05 | Likes discover feed + actions; direct message threads |
| 2026-06-05 | Remove iOS `ActivityBrowse*`; document planned `GET /v1/activities/browse` only |
| 2026-06-05 | CloudBase `spark-api` MVP: full iOS Live path coverage except browse; env matrix + coverage table |
| 2026-06-05 | MODULE-A: CloudBase NoSQL persistence + `GET /v1/activities/browse`; see [MISSING_MODULES_PLAN.md](MISSING_MODULES_PLAN.md) |
