//
//  CommunityView+Search.swift
//  坐标系
//
//  广场系统搜索建议 / 补全；记史仅 onSubmit。
//  不在 isSearching / dismiss 时改 searchText 或偏好（避免与 minimize 抢状态）。
//

import SwiftUI
import CoordinateModels

extension CommunityFeedStack {
    private static let suggestionLimit = 5

    /// 有关键字时视为在搜（与消息 Tab 一致）。
    var isSearchQueryActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 输入为空：最近搜索；有输入：匹配作者 / 标签补全。
    @ViewBuilder
    var communitySearchSuggestions: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            ForEach(feedPreferences.recentSearches, id: \.self) { term in
                Label(term, systemImage: "clock")
                    .searchCompletion(term)
            }
        } else {
            ForEach(searchSuggestionAuthors(matching: query), id: \.self) { name in
                Label(name, systemImage: "person")
                    .searchCompletion(name)
            }
            ForEach(searchSuggestionTags(matching: query), id: \.self) { tag in
                Text("#\(tag)")
                    .searchCompletion(tag)
            }
        }
    }

    func searchSuggestionAuthors(matching query: String) -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for post in model.items {
            let name = post.author
            guard name.localizedCaseInsensitiveContains(query) else { continue }
            let key = name.lowercased()
            guard seen.insert(key).inserted else { continue }
            names.append(name)
            if names.count >= Self.suggestionLimit { break }
        }
        return names
    }

    func searchSuggestionTags(matching query: String) -> [String] {
        var seen = Set<String>()
        var tags: [String] = []
        for post in model.items {
            for tag in post.tags {
                guard tag.localizedCaseInsensitiveContains(query) else { continue }
                let key = tag.lowercased()
                guard seen.insert(key).inserted else { continue }
                tags.append(tag)
                if tags.count >= Self.suggestionLimit { break }
            }
            if tags.count >= Self.suggestionLimit { break }
        }
        return tags
    }

    func rememberCurrentSearchIfNeeded() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        feedPreferences.rememberSearch(query)
    }
}
