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
        starts_at: "2026-06-10T11:00:00Z",
        location_name: "静安寺商圈",
        host_display_name: "小雨",
        host_id: "u_host_2",
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
        replies: [],
      },
    ],
    [
      "cp_003",
      {
        id: "cp_003",
        title: "运动打卡",
        excerpt: "晨跑小组招募",
        body: "每周三次晨跑，欢迎加入。",
        author_display_name: "阿乐",
        author_id: "u_host_1",
        reply_count: 8,
        replies: [],
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

  const likesState = {
    cards: [
      {
        user_id: "u_like_1",
        display_name: "阿乐",
        bio: "徒步、摄影",
        gender: "male",
        is_daily_pick: true,
        rank_score: 12,
        interest_tags: ["hiking", "photo"],
        spark_questions: [
          { id: "sq_1", question: "周末最想做的事？", answer: "郊外徒步" },
        ],
        media: { kind: "image", url: "https://picsum.photos/seed/spark-like-1/1080/1440", poster_url: null },
      },
      {
        user_id: "u_like_2",
        display_name: "小雨",
        bio: "咖啡、聊天、慢生活",
        gender: "female",
        rank_score: 8,
        interest_tags: ["coffee", "chat"],
        spark_questions: [
          { id: "sq_2", question: "理想的周五晚上？", answer: "小馆子里聊天" },
        ],
        media: { kind: "image", url: "https://picsum.photos/seed/spark-like-2/1080/1440", poster_url: null },
      },
      {
        user_id: "u_like_3",
        display_name: "小晨",
        bio: "城市漫步",
        gender: "female",
        rank_score: 5,
        interest_tags: ["walk", "city"],
        media: { kind: "image", url: "https://picsum.photos/seed/spark-like-3/1080/1440", poster_url: null },
      },
    ],
    inbound: [
      {
        user_id: "u_like_5",
        liked_at: "2026-06-05T12:00:00Z",
        intensity: "spark",
        opener: "你的笑容很治愈",
        card: {
          user_id: "u_like_5",
          display_name: "小晨",
          bio: "想认识你",
          gender: "female",
          media: { kind: "image", url: "https://picsum.photos/seed/spark-like-5/1080/1440", poster_url: null },
        },
      },
    ],
    inbound_by_user: {
      u_staging_1: [
        {
          user_id: "u_like_5",
          liked_at: "2026-06-05T12:00:00Z",
          intensity: "spark",
          opener: "你的笑容很治愈",
          card: {
            user_id: "u_like_5",
            display_name: "小晨",
            bio: "想认识你",
            gender: "female",
            media: { kind: "image", url: "https://picsum.photos/seed/spark-like-5/1080/1440", poster_url: null },
          },
        },
      ],
    },
    viewer_profiles: {},
    passed_users: [],
    passed_by_user: {},
    liked_by_me: [],
    liked_by_user: {},
    daily_by_user: {},
    mutual_matches: {
      u_like_1: "th_dm_u_like_1",
      u_like_2: "th_dm_u_like_2",
    },
    inbox_action_items: null,
    dismissed_inbox_action_ids: [],
    last_pass_user_id: null,
    rewind_used_today: false,
    rewind_by_user: {},
  };

  const meta = {
    msg_counter: 100,
    report_counter: 1,
    activity_report_counter: 1,
    activity_counter: 2,
    post_counter: 3,
    reply_counter: 3,
  };

  return { users, activities, communityPosts, threads, likesState, meta };
}

module.exports = { buildSeed };
