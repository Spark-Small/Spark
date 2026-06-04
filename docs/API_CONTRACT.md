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

### `GET /v1/activities/browse` (planned — not in iOS client)

**Status:** Backend / Phase 19 only ([ACTIVITY_UPGRADE_PLAN.md](ACTIVITY_UPGRADE_PLAN.md)). **iOS does not call this path** — public activity discovery was removed with dead `ActivityBrowse*` UI (see [adr/0001-likes-tab-social-discovery.md](adr/0001-likes-tab-social-discovery.md)). **人发现** uses [Likes](#likes-social-discovery) (`GET /v1/likes/feed`).

**Query (draft):** `category`, `starts_after`, `starts_before`, `cursor`

**Response:** Same item shape as [feed](#get-v1activitiesfeed) list entries.

When implementing a future Activity-tab discover screen, add this path to `ActivityAPIPath` and `LiveActivityFeedRepository` in a dedicated PR.

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

**Response `204`:** Token stored for activity push (`activity.reminder`, `activity.cancelled`, `activity.updated`).

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
| GET | `/v1/messages/threads` |
| POST | `/v1/messages/read` |
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
    "reply_count": 12
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

**Response `404`:** Unknown post id.

### Community API path literals (iOS Live)

| Method | Path |
|--------|------|
| GET | `/v1/community/posts` |
| GET | `/v1/community/posts/{post_id}` (built in `CommunityAPIPath.post`) |

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
      "card": { }
    }
  ],
  "next_cursor": null
}
```

`card` uses the same shape as [feed items](#get-v1likesfeed).

---

### `POST /v1/likes/rewind`

Undo the most recent pass (client: once per calendar day recommended).

**Response `200`:** `{ "card": { ... } }` or `{ "card": null }` if unavailable.

---

### `GET /v1/likes/viewer-profile`

Minimum profile for discover gate (like/pass requires `has_photo` + non-empty `display_name`).

**Response `200`:** `{ "display_name": "...", "has_photo": true }`

### `PATCH /v1/likes/viewer-profile`

**Request:** `{ "display_name": "...", "has_photo": true }`

**Response `200`:** Updated profile (same shape as GET).

### Push payloads (APNs)

| `type` | Action |
|--------|--------|
| `likes.inbound` | Open inbound list (`spark://likes/inbound`) |
| `likes.match` | Open DM when `thread_id` set; else inbound |

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

**Deep links (iOS):** `spark://likes` · `spark://likes/inbound` · Universal `https://spark.app/tab/likes` · `https://spark.app/tab/likes/inbound`

**Feed item extensions (optional):** `media_items[]`, `interest_tags[]`, `coarse_location`, `shared_activity: { activity_id, title }`

---

## Environment matrix

| Environment | `SPARK_API_BASE_URL` | iOS data layer |
|-------------|----------------------|----------------|
| Local / no backend | `https://mock.spark.local` | `MockAuthService`, `MockMessagesRepository`, `MockActivityFeedRepository`, `MockLikesFeedRepository`, `MockSearchRepository`, `MockCommunityPostsRepository`, `MockStoreKitService` |
| Staging | `https://api.staging.spark.app` | `Live*` types |
| Production | `https://api.spark.app` | `Live*` types |

Copy `Config/Secrets.xcconfig.example` → `Config/Secrets.xcconfig` (gitignored) to override the base URL without editing shared xcconfig.

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
