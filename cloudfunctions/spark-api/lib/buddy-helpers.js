/**
 * Buddy (搭子) listings — Staging seed + browse filters.
 * Contract: docs/API_CONTRACT.md (camelCase JSON)
 */

const DEFAULT_TRUST = {
  hasIdentityVerified: true,
  hasPhoneVerified: true,
  hasFaceVerified: true,
  hasEmergencyContact: true,
  authenticityScore: 92,
  socialScore: 85,
  talkativenessScore: 88,
  photographyScore: 90,
  localFamiliarityScore: 95,
};

const DEFAULT_PACKAGES = [
  {
    id: "pkg_city_half_day",
    title: "城市漫游",
    durationHours: 4,
    priceAmount: "299",
    priceCurrencyCode: "CNY",
    inclusions: ["本地人陪同讲解", "小众路线规划"],
    exclusions: ["餐饮与门票费用", "私下加价（平台禁止）"],
  },
];

function reviewSnapshot(overrides = {}) {
  const reviews = overrides.reviews || [
    {
      id: "rv_1",
      authorDisplayName: "小林",
      rating: 5,
      comment: "路线规划很贴心，会提前问我想逛什么，拍照也很会找角度。",
      createdAt: "2026-06-12T10:00:00Z",
    },
    {
      id: "rv_2",
      authorDisplayName: "Mia",
      rating: 5,
      comment: "第一次来北京的独自旅行，全程很有安全感，讲解也很专业。",
      createdAt: "2026-05-28T14:30:00Z",
    },
    {
      id: "rv_3",
      authorDisplayName: "阿哲",
      rating: 4,
      comment: "守时靠谱，推荐的小店都很好吃，下次还会约。",
      createdAt: "2026-05-10T09:15:00Z",
    },
  ];
  return {
    punctuality: 4.9,
    communication: 4.8,
    expertise: 4.9,
    safety: 5.0,
    fun: 4.7,
    recommend: 4.9,
    highlightReviews: reviews.slice(0, 2),
    reviews,
    ...overrides,
  };
}

function buildBuddyListings() {
  return new Map([
    [
      "buddy_city_1",
      {
        id: "buddy_city_1",
        ownerUserID: "user_buddy_city_1",
        displayName: "阿Ken",
        avatarURL: "https://picsum.photos/seed/buddy2/200",
        coverURL: "https://picsum.photos/seed/buddy-cover2/800/480",
        introVideoURL: null,
        headline: "城市探店 · 展览同行 · 拍照出片",
        description: "北京本地向导，擅长探店、博物馆、画展等文艺活动。",
        city: "北京",
        serviceCategory: "city_walk",
        billingKind: "daily",
        priceAmount: "599",
        priceCurrencyCode: "CNY",
        tags: ["CityWalk达人", "探店"],
        rating: 4.8,
        reviewCount: 54,
        completedOrderCount: 128,
        isVerified: true,
        supportsOfflineMeetup: true,
        supportsPaidCompanion: false,
        trust: DEFAULT_TRUST,
        matchInsight: { matchPercent: 89, reason: "你们都喜欢 CityWalk 与咖啡文化。" },
        packages: DEFAULT_PACKAGES,
        reviewSnapshot: reviewSnapshot(),
      },
    ],
    [
      "buddy_food_1",
      {
        id: "buddy_food_1",
        ownerUserID: "user_buddy_food_1",
        displayName: "柚子",
        avatarURL: "https://picsum.photos/seed/buddy-food/200",
        coverURL: "https://picsum.photos/seed/buddy-food-cover/800/480",
        introVideoURL: null,
        headline: "本地人带你吃 · 避雷饭托",
        description: "成都土著，熟悉苍蝇馆子和深夜食堂。",
        city: "成都",
        serviceCategory: "food",
        billingKind: "per_project",
        priceAmount: "399",
        priceCurrencyCode: "CNY",
        tags: ["美食达人"],
        rating: 4.9,
        reviewCount: 203,
        completedOrderCount: 310,
        isVerified: true,
        supportsOfflineMeetup: true,
        supportsPaidCompanion: true,
        trust: DEFAULT_TRUST,
        matchInsight: { matchPercent: 86, reason: "你们都偏好慢节奏、深度探索型出行。" },
        packages: [DEFAULT_PACKAGES[0]],
        reviewSnapshot: reviewSnapshot({
          expertise: 4.8,
          fun: 4.9,
          reviews: [
            {
              id: "rv_food_1",
              authorDisplayName: "阿哲",
              rating: 5,
              comment: "带我们避开了网红排队坑，苍蝇馆子巨好吃。",
              createdAt: "2026-06-20T18:00:00Z",
            },
          ],
        }),
      },
    ],
    [
      "buddy_photo_1",
      {
        id: "buddy_photo_1",
        ownerUserID: "user_buddy_photo_1",
        displayName: "Luna",
        avatarURL: "https://picsum.photos/seed/buddy-photo/200",
        coverURL: "https://picsum.photos/seed/buddy-photo-cover/800/480",
        introVideoURL: null,
        headline: "旅拍陪拍 · 夜景人像",
        description: "上海摄影师，擅长街拍与夜景。",
        city: "上海",
        serviceCategory: "photography",
        billingKind: "hourly",
        priceAmount: "120",
        priceCurrencyCode: "CNY",
        tags: ["摄影达人"],
        rating: 5.0,
        reviewCount: 87,
        completedOrderCount: 156,
        isVerified: true,
        supportsOfflineMeetup: true,
        supportsPaidCompanion: true,
        trust: { ...DEFAULT_TRUST, photographyScore: 98 },
        matchInsight: { matchPercent: 91, reason: "你们都标记了「记录价值」出行偏好。" },
        packages: DEFAULT_PACKAGES,
        reviewSnapshot: reviewSnapshot({ expertise: 5.0, recommend: 5.0 }),
      },
    ],
    [
      "buddy_night_1",
      {
        id: "buddy_night_1",
        ownerUserID: "user_buddy_night_1",
        displayName: "K",
        avatarURL: "https://picsum.photos/seed/buddy-night/200",
        coverURL: "https://picsum.photos/seed/buddy-night-cover/800/480",
        introVideoURL: null,
        headline: "酒吧向导 · 安全夜生活",
        description: "深圳夜生活达人，熟悉安全路线与靠谱商户。",
        city: "深圳",
        serviceCategory: "nightlife",
        billingKind: "hourly",
        priceAmount: "150",
        priceCurrencyCode: "CNY",
        tags: ["夜景达人"],
        rating: 4.7,
        reviewCount: 42,
        completedOrderCount: 67,
        isVerified: true,
        supportsOfflineMeetup: true,
        supportsPaidCompanion: true,
        trust: DEFAULT_TRUST,
        packages: DEFAULT_PACKAGES,
        reviewSnapshot: reviewSnapshot({ safety: 5.0, fun: 4.9 }),
      },
    ],
    [
      "buddy_event_1",
      {
        id: "buddy_event_1",
        ownerUserID: "user_buddy_event_1",
        displayName: "Mia",
        avatarURL: "https://picsum.photos/seed/buddy3/200",
        coverURL: "https://picsum.photos/seed/buddy-cover3/800/480",
        introVideoURL: null,
        headline: "演唱会/音乐节同行 · 行程规划",
        description: "大湾区演出资讯达人，可协助购票、规划行程。",
        city: "深圳",
        serviceCategory: "culture",
        billingKind: "per_project",
        priceAmount: "299",
        priceCurrencyCode: "CNY",
        tags: ["活动"],
        rating: 5.0,
        reviewCount: 31,
        completedOrderCount: 45,
        isVerified: false,
        supportsOfflineMeetup: true,
        supportsPaidCompanion: true,
        trust: {
          hasIdentityVerified: true,
          hasPhoneVerified: true,
          hasFaceVerified: false,
          hasEmergencyContact: true,
          authenticityScore: 84,
        },
        packages: DEFAULT_PACKAGES,
        reviewSnapshot: reviewSnapshot({ punctuality: 5.0 }),
      },
    ],
    [
      "buddy_outdoor_1",
      {
        id: "buddy_outdoor_1",
        ownerUserID: "user_buddy_outdoor_1",
        displayName: "山行",
        avatarURL: "https://picsum.photos/seed/buddy4/200",
        coverURL: "https://picsum.photos/seed/buddy-cover4/800/480",
        introVideoURL: null,
        headline: "周末徒步 · 露营搭子",
        description: "杭州周边户外爱好者，熟悉天目山、莫干山线路。",
        city: "杭州",
        serviceCategory: "sports",
        billingKind: "daily",
        priceAmount: "450",
        priceCurrencyCode: "CNY",
        tags: ["户外"],
        rating: 4.7,
        reviewCount: 89,
        completedOrderCount: 112,
        isVerified: true,
        supportsOfflineMeetup: true,
        supportsPaidCompanion: false,
        trust: DEFAULT_TRUST,
        packages: DEFAULT_PACKAGES,
        reviewSnapshot: reviewSnapshot({ punctuality: 4.8, expertise: 4.7 }),
      },
    ],
  ]);
}

function serializeBuddyListing(listing) {
  return { ...listing };
}

function browseBuddies(listingsMap, query) {
  const { category, billing, cursor } = query;
  let items = [...listingsMap.values()];
  if (category) {
    items = items.filter((item) => item.serviceCategory === category);
  }
  if (billing) {
    items = items.filter((item) => item.billingKind === billing);
  }
  items.sort((a, b) => (b.rating || 0) - (a.rating || 0));

  const pageSize = 20;
  let startIndex = 0;
  if (cursor) {
    const idx = items.findIndex((item) => item.id === cursor);
    startIndex = idx >= 0 ? idx + 1 : 0;
  }
  const page = items.slice(startIndex, startIndex + pageSize);
  const hasMore = startIndex + pageSize < items.length;
  const nextCursor = hasMore && page.length > 0 ? page[page.length - 1].id : null;
  return { page, nextCursor };
}

function defaultProviderStatus() {
  return { state: "none", submittedAt: null, reviewedAt: null, rejectionReason: null };
}

function serializeProviderStatus(status) {
  return {
    state: status.state,
    submittedAt: status.submittedAt,
    reviewedAt: status.reviewedAt,
    rejectionReason: status.rejectionReason ?? null,
  };
}

module.exports = {
  buildBuddyListings,
  serializeBuddyListing,
  browseBuddies,
  defaultProviderStatus,
  serializeProviderStatus,
};
