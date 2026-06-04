// Module: SparkSearchTests

import SparkSearch
import Testing

struct SearchResultKindTests {
    @Test func wireValueParsesEnglishKinds() {
        #expect(SearchResultKind(wireValue: "community") == .community)
        #expect(SearchResultKind(wireValue: "activity") == .activity)
    }

    @Test func wireValueParsesLegacyLocalizedKinds() {
        #expect(SearchResultKind(wireValue: "社区") == .community)
        #expect(SearchResultKind(wireValue: "活动") == .activity)
    }

    @Test func communitySupportsNavigation() {
        let item = SearchResultItem(id: "cp_2", title: "t", subtitle: "s", kind: "community")
        #expect(item.resultKind?.supportsInAppNavigation == true)
    }

    @Test func localizedCommunityKindSupportsNavigation() {
        let item = SearchResultItem(id: "cp_2", title: "t", subtitle: "s", kind: "社区")
        #expect(item.resultKind?.supportsInAppNavigation == true)
    }
}
