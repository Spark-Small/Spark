import CoordinateDomain
import CoordinateModels
import XCTest

final class ActivitiesBrowseUseCaseTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFilterNearbyExcludesPastActivities() {
        let past = Activity(
            id: UUID(),
            title: "Past",
            category: .food,
            location: "成都",
            date: now.addingTimeInterval(-3600),
            capacity: 10,
            joined: 2,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: [],
            distanceKM: 1.0
        )
        let upcoming = Activity(
            id: UUID(),
            title: "Soon",
            category: .food,
            location: "成都",
            date: now.addingTimeInterval(3600),
            capacity: 10,
            joined: 2,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: [],
            distanceKM: 1.0
        )
        let criteria = ActivityBrowseCriteria(
            category: .forYou,
            quickFilters: [.nearby],
            nearbyRadiusKM: 3.0,
            now: now
        )

        let filtered = FilterActivitiesBrowseUseCase().execute(
            activities: [past, upcoming],
            criteria: criteria
        )

        XCTAssertEqual(filtered.map(\.title), ["Soon"])
    }

    func testFilterByCategory() {
        let food = Activity(
            id: UUID(),
            title: "吃",
            category: .food,
            location: "成都",
            date: now.addingTimeInterval(3600),
            capacity: 10,
            joined: 0,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: []
        )
        let outdoor = Activity(
            id: UUID(),
            title: "跑",
            category: .outdoorSports,
            location: "成都",
            date: now.addingTimeInterval(3600),
            capacity: 10,
            joined: 0,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: []
        )
        let criteria = ActivityBrowseCriteria(
            category: .food,
            quickFilters: [],
            nearbyRadiusKM: 3.0,
            now: now
        )

        let filtered = FilterActivitiesBrowseUseCase().execute(
            activities: [food, outdoor],
            criteria: criteria
        )

        XCTAssertEqual(filtered.map(\.title), ["吃"])
    }

    func testFilterBySearchTextMatchesTitleLocationHostAndTags() {
        let bike = Activity(
            id: UUID(),
            title: "夜骑外滩",
            category: .outdoorSports,
            location: "上海外滩",
            date: now.addingTimeInterval(3600),
            capacity: 10,
            joined: 0,
            hostName: "阿凯",
            summary: "晚风局",
            fee: "免费",
            tags: ["骑行", "夜景"]
        )
        let dinner = Activity(
            id: UUID(),
            title: "火锅局",
            category: .food,
            location: "成都",
            date: now.addingTimeInterval(3600),
            capacity: 10,
            joined: 0,
            hostName: "小周",
            summary: "吃吃喝喝",
            fee: "AA",
            tags: ["美食"]
        )

        let byTitle = FilterActivitiesBrowseUseCase().execute(
            activities: [bike, dinner],
            criteria: ActivityBrowseCriteria(
                category: .forYou,
                quickFilters: [],
                nearbyRadiusKM: 10,
                searchText: "夜骑",
                now: now
            )
        )
        XCTAssertEqual(byTitle.map(\.title), ["夜骑外滩"])

        let byHost = FilterActivitiesBrowseUseCase().execute(
            activities: [bike, dinner],
            criteria: ActivityBrowseCriteria(
                category: .forYou,
                quickFilters: [],
                nearbyRadiusKM: 10,
                searchText: "小周",
                now: now
            )
        )
        XCTAssertEqual(byHost.map(\.title), ["火锅局"])

        let byTag = FilterActivitiesBrowseUseCase().execute(
            activities: [bike, dinner],
            criteria: ActivityBrowseCriteria(
                category: .forYou,
                quickFilters: [],
                nearbyRadiusKM: 10,
                searchText: "骑行",
                now: now
            )
        )
        XCTAssertEqual(byTag.map(\.title), ["夜骑外滩"])
    }
}
