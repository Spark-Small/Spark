// Module: SparkBuddy — Rich mock catalog aligned with trust-first companion PRD.

import Foundation

enum MockBuddyCatalog {
    static let listings: [BuddyListing] = [
        cityWalkListing,
        foodListing,
        photoListing,
        nightlifeListing,
        cultureListing,
        sportsListing
    ]

    private static var standardPackages: [BuddyServicePackage] {
        [
            BuddyServicePackage(
                id: "pkg_city_half_day",
                title: String(
                    localized: "buddy.package.cityWalk.title",
                    defaultValue: "城市漫游",
                    comment: "City walk package"
                ),
                durationHours: 4,
                priceAmount: 299,
                priceCurrencyCode: "CNY",
                inclusions: [
                    String(
                        localized: "buddy.package.inclusion.guide",
                        defaultValue: "本地人陪同讲解",
                        comment: "Local guide inclusion"
                    ),
                    String(
                        localized: "buddy.package.inclusion.route",
                        defaultValue: "小众路线规划",
                        comment: "Route planning"
                    )
                ],
                exclusions: [
                    String(
                        localized: "buddy.package.exclusion.meal",
                        defaultValue: "餐饮与门票费用",
                        comment: "Meals excluded"
                    ),
                    String(
                        localized: "buddy.package.exclusion.privateFee",
                        defaultValue: "私下加价（平台禁止）",
                        comment: "No private fees"
                    )
                ]
            ),
            BuddyServicePackage(
                id: "pkg_food_day",
                title: String(
                    localized: "buddy.package.food.title",
                    defaultValue: "美食陪玩",
                    comment: "Food package"
                ),
                durationHours: 6,
                priceAmount: 399,
                priceCurrencyCode: "CNY",
                inclusions: [
                    String(
                        localized: "buddy.package.inclusion.foodGuide",
                        defaultValue: "苍蝇馆子/网红店避雷",
                        comment: "Food guide"
                    )
                ],
                exclusions: [
                    String(
                        localized: "buddy.package.exclusion.meal",
                        defaultValue: "餐饮与门票费用",
                        comment: "Meals excluded"
                    )
                ]
            ),
            BuddyServicePackage(
                id: "pkg_photo_day",
                title: String(
                    localized: "buddy.package.photo.title",
                    defaultValue: "摄影陪拍",
                    comment: "Photo package"
                ),
                durationHours: 8,
                priceAmount: 599,
                priceCurrencyCode: "CNY",
                inclusions: [
                    String(
                        localized: "buddy.package.inclusion.photo",
                        defaultValue: "机位推荐 + 基础修图",
                        comment: "Photo service"
                    )
                ],
                exclusions: [
                    String(
                        localized: "buddy.package.exclusion.transport",
                        defaultValue: "跨城交通",
                        comment: "Transport excluded"
                    )
                ]
            )
        ]
    }

    private static var fullTrust: BuddyTrustProfile {
        BuddyTrustProfile(
            hasIdentityVerified: true,
            hasPhoneVerified: true,
            hasFaceVerified: true,
            hasEmergencyContact: true,
            authenticityScore: 92,
            socialScore: 85,
            talkativenessScore: 88,
            photographyScore: 90,
            localFamiliarityScore: 95
        )
    }

    private static func reviewSnapshot(
        punctuality: Double = 4.9,
        communication: Double = 4.8,
        expertise: Double = 4.9,
        safety: Double = 5.0,
        fun: Double = 4.7,
        recommend: Double = 4.9,
        reviews: [BuddyReview]
    ) -> BuddyReviewSnapshot {
        BuddyReviewSnapshot(
            punctuality: punctuality,
            communication: communication,
            expertise: expertise,
            safety: safety,
            fun: fun,
            recommend: recommend,
            reviews: reviews
        )
    }

    private static func reviewDate(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
    }

    private static var cityWalkReviews: BuddyReviewSnapshot {
        reviewSnapshot(
            reviews: [
                BuddyReview(
                    id: "rv_city_1",
                    authorDisplayName: "小林",
                    rating: 5,
                    comment: String(
                        localized: "buddy.mock.review.city.1",
                        defaultValue: "路线规划很贴心，会提前问我想逛什么，拍照也很会找角度，整体体验超出预期。",
                        comment: "Mock city review 1"
                    ),
                    createdAt: reviewDate(daysAgo: 12)
                ),
                BuddyReview(
                    id: "rv_city_2",
                    authorDisplayName: "Mia",
                    rating: 5,
                    comment: String(
                        localized: "buddy.mock.review.city.2",
                        defaultValue: "第一次来北京的独自旅行，全程很有安全感，讲解也很专业，强烈推荐。",
                        comment: "Mock city review 2"
                    ),
                    createdAt: reviewDate(daysAgo: 34)
                )
            ]
        )
    }

    private static var foodReviews: BuddyReviewSnapshot {
        reviewSnapshot(
            expertise: 4.8,
            fun: 4.9,
            reviews: [
                BuddyReview(
                    id: "rv_food_1",
                    authorDisplayName: "阿哲",
                    rating: 5,
                    comment: String(
                        localized: "buddy.mock.review.food.1",
                        defaultValue: "带我们避开了网红排队坑，苍蝇馆子巨好吃，还会介绍本地吃法，值回票价。",
                        comment: "Mock food review 1"
                    ),
                    createdAt: reviewDate(daysAgo: 8)
                )
            ]
        )
    }

    private static var photoReviews: BuddyReviewSnapshot {
        reviewSnapshot(
            expertise: 5.0,
            fun: 4.8,
            recommend: 5.0,
            reviews: [
                BuddyReview(
                    id: "rv_photo_1",
                    authorDisplayName: "橙子",
                    rating: 5,
                    comment: String(
                        localized: "buddy.mock.review.photo.1",
                        defaultValue: "夜景人像拍得超好，会教摆姿，修图风格自然，已经推荐给朋友了。",
                        comment: "Mock photo review 1"
                    ),
                    createdAt: reviewDate(daysAgo: 5)
                ),
                BuddyReview(
                    id: "rv_photo_2",
                    authorDisplayName: "Jay",
                    rating: 5,
                    comment: String(
                        localized: "buddy.mock.review.photo.2",
                        defaultValue: "提前发了机位参考，现场很专业，出片效率高，沟通也很顺畅。",
                        comment: "Mock photo review 2"
                    ),
                    createdAt: reviewDate(daysAgo: 21)
                )
            ]
        )
    }

    private static var nightlifeReviews: BuddyReviewSnapshot {
        reviewSnapshot(
            safety: 5.0,
            fun: 4.9,
            reviews: [
                BuddyReview(
                    id: "rv_night_1",
                    authorDisplayName: "游客A",
                    rating: 5,
                    comment: String(
                        localized: "buddy.mock.review.night.1",
                        defaultValue: "女生独自出行也觉得很安全，推荐的酒吧都很靠谱，没有隐形消费。",
                        comment: "Mock nightlife review 1"
                    ),
                    createdAt: reviewDate(daysAgo: 16)
                )
            ]
        )
    }

    private static var cultureReviews: BuddyReviewSnapshot {
        reviewSnapshot(
            punctuality: 5.0,
            expertise: 4.9,
            reviews: [
                BuddyReview(
                    id: "rv_culture_1",
                    authorDisplayName: "歌迷小陈",
                    rating: 5,
                    comment: String(
                        localized: "buddy.mock.review.culture.1",
                        defaultValue: "演唱会行程安排得很细，接送和入场都帮想到了，省心很多。",
                        comment: "Mock culture review 1"
                    ),
                    createdAt: reviewDate(daysAgo: 19)
                )
            ]
        )
    }

    private static var sportsReviews: BuddyReviewSnapshot {
        reviewSnapshot(
            punctuality: 4.8,
            expertise: 4.7,
            fun: 4.8,
            reviews: [
                BuddyReview(
                    id: "rv_sports_1",
                    authorDisplayName: "跑者Leo",
                    rating: 5,
                    comment: String(
                        localized: "buddy.mock.review.sports.1",
                        defaultValue: "徒步节奏把控很好，会随时关注体力，风景路线也选得很棒。",
                        comment: "Mock sports review 1"
                    ),
                    createdAt: reviewDate(daysAgo: 27)
                )
            ]
        )
    }

    private static var cityWalkListing: BuddyListing {
        BuddyListing(
            id: "buddy_city_1",
            ownerUserID: "user_buddy_city_1",
            displayName: "阿Ken",
            avatarURL: URL(string: "https://picsum.photos/seed/buddy2/200"),
            coverURL: URL(string: "https://picsum.photos/seed/buddy-cover2/800/480"),
            headline: String(
                localized: "buddy.mock.city.headline",
                defaultValue: "城市探店 · 展览同行 · 拍照出片",
                comment: "Mock city buddy headline"
            ),
            description: String(
                localized: "buddy.mock.city.description",
                defaultValue: "北京本地向导，擅长探店、博物馆、画展等文艺活动。熟悉三里屯、798、南锣鼓巷等地。拍照出片，帮你记录美好瞬间。",
                comment: "Mock city buddy description"
            ),
            city: String(localized: "buddy.mock.city.beijing", defaultValue: "北京", comment: "Mock city"),
            serviceCategory: .cityWalk,
            billingKind: .daily,
            priceAmount: 599,
            priceCurrencyCode: "CNY",
            tags: [
                String(localized: "buddy.mock.tag.cityWalk", defaultValue: "CityWalk达人", comment: "CityWalk tag"),
                String(localized: "buddy.mock.tag.explore", defaultValue: "探店", comment: "Explore tag")
            ],
            rating: 4.8,
            reviewCount: 54,
            completedOrderCount: 128,
            isVerified: true,
            supportsOfflineMeetup: true,
            supportsPaidCompanion: false,
            trust: fullTrust,
            matchInsight: BuddyMatchInsight(
                matchPercent: 89,
                reason: String(
                    localized: "buddy.mock.match.cityWalk",
                    defaultValue: "你们都喜欢 CityWalk 与咖啡文化。",
                    comment: "Mock match reason"
                )
            ),
            packages: standardPackages,
            reviewSnapshot: cityWalkReviews
        )
    }

    private static var foodListing: BuddyListing {
        BuddyListing(
            id: "buddy_food_1",
            ownerUserID: "user_buddy_food_1",
            displayName: "柚子",
            avatarURL: URL(string: "https://picsum.photos/seed/buddy-food/200"),
            coverURL: URL(string: "https://picsum.photos/seed/buddy-food-cover/800/480"),
            headline: String(
                localized: "buddy.mock.food.headline",
                defaultValue: "本地人带你吃 · 避雷饭托",
                comment: "Food buddy headline"
            ),
            description: String(
                localized: "buddy.mock.food.description",
                defaultValue: "成都土著，熟悉苍蝇馆子和深夜食堂。平台托管付款，拒绝隐形消费与酒托饭托。",
                comment: "Food buddy description"
            ),
            city: String(localized: "buddy.mock.city.chengdu", defaultValue: "成都", comment: "Mock city"),
            serviceCategory: .food,
            billingKind: .perProject,
            priceAmount: 399,
            priceCurrencyCode: "CNY",
            tags: [
                String(localized: "buddy.mock.tag.food", defaultValue: "美食达人", comment: "Food tag")
            ],
            rating: 4.9,
            reviewCount: 203,
            completedOrderCount: 310,
            isVerified: true,
            supportsOfflineMeetup: true,
            supportsPaidCompanion: true,
            trust: fullTrust,
            matchInsight: BuddyMatchInsight(
                matchPercent: 86,
                reason: String(
                    localized: "buddy.mock.match.food",
                    defaultValue: "你们都偏好慢节奏、深度探索型出行。",
                    comment: "Food match reason"
                )
            ),
            packages: [standardPackages[1]],
            reviewSnapshot: foodReviews
        )
    }

    private static var photoListing: BuddyListing {
        BuddyListing(
            id: "buddy_photo_1",
            ownerUserID: "user_buddy_photo_1",
            displayName: "Luna",
            avatarURL: URL(string: "https://picsum.photos/seed/buddy-photo/200"),
            coverURL: URL(string: "https://picsum.photos/seed/buddy-photo-cover/800/480"),
            headline: String(
                localized: "buddy.mock.photo.headline",
                defaultValue: "旅拍陪拍 · 夜景人像",
                comment: "Photo buddy headline"
            ),
            description: String(
                localized: "buddy.mock.photo.description",
                defaultValue: "上海摄影师，擅长街拍与夜景。可提供行程模拟与机位推荐，服务前可 15 分钟语音预聊。",
                comment: "Photo buddy description"
            ),
            city: String(localized: "buddy.mock.city.shanghai", defaultValue: "上海", comment: "Mock city"),
            serviceCategory: .photography,
            billingKind: .hourly,
            priceAmount: 120,
            priceCurrencyCode: "CNY",
            tags: [
                String(localized: "buddy.mock.tag.photoPro", defaultValue: "摄影达人", comment: "Photo pro tag")
            ],
            rating: 5.0,
            reviewCount: 87,
            completedOrderCount: 156,
            isVerified: true,
            supportsOfflineMeetup: true,
            supportsPaidCompanion: true,
            trust: BuddyTrustProfile(
                hasIdentityVerified: true,
                hasPhoneVerified: true,
                hasFaceVerified: true,
                hasEmergencyContact: true,
                authenticityScore: 96,
                socialScore: 78,
                talkativenessScore: 72,
                photographyScore: 98,
                localFamiliarityScore: 91
            ),
            matchInsight: BuddyMatchInsight(
                matchPercent: 91,
                reason: String(
                    localized: "buddy.mock.match.photo",
                    defaultValue: "你们都标记了「记录价值」出行偏好。",
                    comment: "Photo match reason"
                )
            ),
            packages: [standardPackages[2]],
            reviewSnapshot: photoReviews
        )
    }

    private static var nightlifeListing: BuddyListing {
        BuddyListing(
            id: "buddy_night_1",
            ownerUserID: "user_buddy_night_1",
            displayName: "K",
            avatarURL: URL(string: "https://picsum.photos/seed/buddy-night/200"),
            coverURL: URL(string: "https://picsum.photos/seed/buddy-night-cover/800/480"),
            headline: String(
                localized: "buddy.mock.night.headline",
                defaultValue: "酒吧向导 · 安全夜生活",
                comment: "Nightlife headline"
            ),
            description: String(
                localized: "buddy.mock.night.description",
                defaultValue: "深圳夜生活达人，熟悉安全路线与靠谱商户。全程平台定位护航，一键 SOS。",
                comment: "Nightlife description"
            ),
            city: String(localized: "buddy.mock.city.shenzhen", defaultValue: "深圳", comment: "Mock city"),
            serviceCategory: .nightlife,
            billingKind: .hourly,
            priceAmount: 150,
            priceCurrencyCode: "CNY",
            tags: [
                String(localized: "buddy.mock.tag.night", defaultValue: "夜景达人", comment: "Night tag")
            ],
            rating: 4.7,
            reviewCount: 42,
            completedOrderCount: 67,
            isVerified: true,
            supportsOfflineMeetup: true,
            supportsPaidCompanion: true,
            trust: fullTrust,
            packages: standardPackages,
            reviewSnapshot: nightlifeReviews
        )
    }

    private static var cultureListing: BuddyListing {
        BuddyListing(
            id: "buddy_event_1",
            ownerUserID: "user_buddy_event_1",
            displayName: "Mia",
            avatarURL: URL(string: "https://picsum.photos/seed/buddy3/200"),
            coverURL: URL(string: "https://picsum.photos/seed/buddy-cover3/800/480"),
            headline: String(
                localized: "buddy.mock.event.headline",
                defaultValue: "演唱会/音乐节同行 · 行程规划",
                comment: "Mock event buddy headline"
            ),
            description: String(
                localized: "buddy.mock.event.description",
                defaultValue: "大湾区演出资讯达人，可协助购票、规划行程。项目制收费，价格透明。",
                comment: "Mock event buddy description"
            ),
            city: String(localized: "buddy.mock.city.shenzhen", defaultValue: "深圳", comment: "Mock city"),
            serviceCategory: .culture,
            billingKind: .perProject,
            priceAmount: 299,
            priceCurrencyCode: "CNY",
            tags: [
                String(localized: "buddy.mock.tag.event", defaultValue: "活动", comment: "Event tag")
            ],
            rating: 5.0,
            reviewCount: 31,
            completedOrderCount: 45,
            isVerified: false,
            supportsOfflineMeetup: true,
            supportsPaidCompanion: true,
            trust: BuddyTrustProfile(
                hasIdentityVerified: true,
                hasPhoneVerified: true,
                hasFaceVerified: false,
                hasEmergencyContact: true,
                authenticityScore: 84
            ),
            packages: standardPackages,
            reviewSnapshot: cultureReviews
        )
    }

    private static var sportsListing: BuddyListing {
        BuddyListing(
            id: "buddy_outdoor_1",
            ownerUserID: "user_buddy_outdoor_1",
            displayName: "山行",
            avatarURL: URL(string: "https://picsum.photos/seed/buddy4/200"),
            coverURL: URL(string: "https://picsum.photos/seed/buddy-cover4/800/480"),
            headline: String(
                localized: "buddy.mock.outdoor.headline",
                defaultValue: "周末徒步 · 露营搭子",
                comment: "Mock outdoor buddy headline"
            ),
            description: String(
                localized: "buddy.mock.outdoor.description",
                defaultValue: "杭州周边户外爱好者，熟悉天目山、莫干山线路。装备齐全，有急救证书。",
                comment: "Mock outdoor buddy description"
            ),
            city: String(localized: "buddy.mock.city.hangzhou", defaultValue: "杭州", comment: "Mock city"),
            serviceCategory: .sports,
            billingKind: .daily,
            priceAmount: 450,
            priceCurrencyCode: "CNY",
            tags: [
                String(localized: "buddy.mock.tag.outdoor", defaultValue: "户外", comment: "Outdoor tag")
            ],
            rating: 4.7,
            reviewCount: 89,
            completedOrderCount: 112,
            isVerified: true,
            supportsOfflineMeetup: true,
            supportsPaidCompanion: false,
            trust: fullTrust,
            packages: standardPackages,
            reviewSnapshot: sportsReviews
        )
    }
}
