/** Community tab feed, groups, members, and linked activities (staging mock). */

const JOINED_COMMUNITY_IDS = ["cm_hike", "cm_book", "cm_photo"];

const COMMUNITIES = [
  {
    id: "cm_hike",
    name: "爬山队",
    cover_url: "https://picsum.photos/seed/cm-hike/112/112",
    member_count: 38,
    activity_count: 12,
    has_new_posts: true,
    bio: "一起去爬山的人都不会太差",
  },
  {
    id: "cm_book",
    name: "读书会",
    cover_url: "https://picsum.photos/seed/cm-book/112/112",
    member_count: 21,
    activity_count: 4,
    has_new_posts: false,
    bio: "",
  },
  {
    id: "cm_photo",
    name: "摄影组",
    cover_url: "https://picsum.photos/seed/cm-photo/112/112",
    member_count: 54,
    activity_count: 8,
    has_new_posts: true,
    bio: "",
  },
  {
    id: "cm_run",
    name: "晨跑打卡",
    cover_url: "https://picsum.photos/seed/cm-run/112/112",
    member_count: 67,
    activity_count: 20,
    has_new_posts: false,
    bio: "滨江沿线，配速随缘",
  },
];

const DISCOVERED_PEOPLE = [
  {
    id: "u_like_1",
    display_name: "李明",
    avatar_url: "https://picsum.photos/seed/person-1/96/96",
    shared_tag: "爬山",
    relationship: "shared_activity",
  },
  {
    id: "u_like_2",
    display_name: "王芳",
    avatar_url: "https://picsum.photos/seed/person-2/96/96",
    shared_tag: "读书",
    relationship: "shared_activity",
  },
  {
    id: "u_like_3",
    display_name: "张伟",
    avatar_url: "https://picsum.photos/seed/person-3/96/96",
    shared_tag: "摄影",
    relationship: "liked",
  },
];

const COMMUNITY_ACTIVITIES = {
  cm_hike: [
    { id: "act_001", title: "周末爬香山", schedule_line: "周六 9:30" },
    { id: "act_002", title: "城郊步道", schedule_line: "下周日 8:00" },
  ],
  cm_book: [{ id: "act_003", title: "咖啡聊天局", schedule_line: "周五 19:00" }],
  cm_photo: [],
  cm_run: [{ id: "act_004", title: "滨江晨跑", schedule_line: "每天 7:00" }],
};

const COMMUNITY_MEMBERS = {
  cm_hike: [
    {
      id: "u_host_1",
      display_name: "阿乐",
      avatar_url: "https://picsum.photos/seed/person-1/96/96",
      bio: "周末爬山",
      relationship_to_viewer: "shared_activity",
    },
    {
      id: "u_host_2",
      display_name: "小雨",
      avatar_url: "https://picsum.photos/seed/person-2/96/96",
      bio: "滨江跑步",
      relationship_to_viewer: "liked",
    },
  ],
  cm_book: [
    {
      id: "u_guest_1",
      display_name: "Nova",
      avatar_url: "https://picsum.photos/seed/person-3/96/96",
      bio: "喜欢聊天局",
      relationship_to_viewer: "none",
    },
  ],
};

function communityById(id) {
  return COMMUNITIES.find((c) => c.id === id) || null;
}

function feedPostFromListPost(post, viewerUserId) {
  const likers = Array.isArray(post.likers) ? post.likers : [];
  return {
    id: post.id,
    author_display_name: post.author_display_name,
    author_user_id: post.author_id || post.id,
    community_name: "社区",
    content: post.excerpt || post.body || post.title,
    image_url: null,
    like_count: post.like_count ?? likers.length,
    viewer_has_liked: viewerUserId ? likers.includes(viewerUserId) : false,
    comment_count: post.reply_count || 0,
    tags: [],
    created_at: new Date().toISOString(),
    shared_activity_with_viewer: null,
    relationship_to_viewer: "none",
    linked_activity:
      post.id === "cp_001"
        ? { id: "act_001", name: "周末爬香山" }
        : null,
  };
}

function buildCommunityFeed(state, viewerUserId) {
  const posts = [...state.communityPosts.values()].map((post) => feedPostFromListPost(post, viewerUserId));
  const items = [];
  posts.forEach((post, index) => {
    items.push({ type: "post", post, people: null });
    if ((index + 1) % 5 === 0) {
      items.push({ type: "people_discovery", post: null, people: DISCOVERED_PEOPLE });
    }
  });
  if (items.length === 0 && DISCOVERED_PEOPLE.length > 0) {
    items.push({ type: "people_discovery", post: null, people: DISCOVERED_PEOPLE });
  }
  return {
    joined_communities: COMMUNITIES.filter((c) => JOINED_COMMUNITY_IDS.includes(c.id)),
    items,
    all_communities: COMMUNITIES,
  };
}

function serializeCommunityDetail(id) {
  const c = communityById(id);
  if (!c) return null;
  return {
    ...c,
    is_joined: JOINED_COMMUNITY_IDS.includes(id),
  };
}

function serializeCommunityActivities(id) {
  return COMMUNITY_ACTIVITIES[id] || [];
}

function serializeCommunityMembers(id) {
  return COMMUNITY_MEMBERS[id] || [];
}

module.exports = {
  buildCommunityFeed,
  serializeCommunityDetail,
  serializeCommunityActivities,
  serializeCommunityMembers,
  communityById,
};
