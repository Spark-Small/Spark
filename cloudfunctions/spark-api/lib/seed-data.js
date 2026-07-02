/**
 * Staging seed — loaded into memory and persisted when DB is empty.
 * Contract shapes: docs/API_CONTRACT.md
 */

function buildSeed() {
  const users = {
    "staging@test.com": { password: "staging123", user_id: "u_staging_1", name: "Staging User" },
  };

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
        waitlisted_count: 0,
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
        starts_at: "2026-06-06T19:00:00Z",
        ends_at: "2026-06-06T21:00:00Z",
        recurrence: {
          frequency: "weekly",
          weekday: "friday",
          until: "2027-06-06T21:00:00Z",
        },
        location_name: "静安寺商圈",
        host_display_name: "小雨",
        host_id: "u_host_2",
        host_tier: "super_organizer",
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
        author_id: "u_host_1",
        reply_count: 2,
        like_count: 6,
        likers: [],
        replies: [
          {
            id: "cpr_001",
            body: "周六可以，几点集合？",
            author_display_name: "小雨",
            author_id: "u_host_2",
            created_at: "2026-06-01T10:00:00.000Z",
          },
          {
            id: "cpr_002",
            body: "上午 9 点地铁站见。",
            author_display_name: "阿乐",
            author_id: "u_host_1",
            created_at: "2026-06-01T11:30:00.000Z",
          },
        ],
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
        author_id: "u_host_2",
        reply_count: 5,
        like_count: 3,
        likers: [],
        replies: [],
      },
    ],
    [
      "cp_003",
      {
        id: "cp_003",
        title: "咖啡聊天局复盘",
        excerpt: "上次聊天局氛围很好，下次想试试早场。",
        body: "上次聊天局氛围很好，下次想试试早场，人少更专注。",
        author_display_name: "Nova",
        author_id: "u_host_1",
        reply_count: 0,
        like_count: 9,
        likers: [],
        replies: [],
        kind: "activity_recap",
        activity_id: "act_browse_2",
        linked_activity: { id: "act_browse_2", name: "玉林咖啡聊天局" },
      },
    ],
  ]);

  const threads = new Map([
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

  const inboxState = {
    viewer_profiles: {},
    mutual_matches: {
      u_like_1: "th_dm_u_like_1",
      u_like_2: "th_dm_u_like_2",
    },
    inbox_action_items: null,
    dismissed_inbox_action_ids: [],
  };

  const meta = {
    msg_counter: 100,
    report_counter: 1,
    activity_report_counter: 1,
    activity_counter: 2,
    post_counter: 3,
    reply_counter: 3,
  };

  return { users, activities, communityPosts, threads, inboxState, meta };
}

module.exports = { buildSeed };
