// Module: SparkSearch — Shared search results list (standalone page + tab-role overlay).

import SparkDesignSystem
import SwiftUI

struct SearchResultsList: View {
    @Bindable var viewModel: SearchViewModel
    @Binding var selectedPerson: SearchResultItem?
    let onSelectResult: ((SearchResultItem) -> Void)?

    var body: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sparkFeedModuleScroll()
                .sparkLoadingAccessibilityLabel(
                    String(
                        localized: "search.loading.a11y",
                        defaultValue: "正在搜索",
                        comment: "Search loading"
                    )
                )
        case .empty:
            ContentUnavailableView(
                String(localized: "search.empty.title", defaultValue: "无结果", comment: "Empty search"),
                systemImage: "magnifyingglass",
                description: Text(
                    String(localized: "search.empty.subtitle", defaultValue: "换个关键词试试", comment: "Empty search hint")
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sparkFeedModuleScroll()
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "search.error.title", defaultValue: "搜索失败", comment: "Search error"),
                description: message
            ) {
                Task { await viewModel.submitSearch() }
            }
        case .loaded:
            List(viewModel.results) { item in
                if item.resultKind == .person {
                    Button {
                        selectedPerson = item
                    } label: {
                        SearchResultRow(item: item, showsChevron: true)
                    }
                    .buttonStyle(.sparkPressable)
                    .sparkSemanticListRow()
                } else if let onSelectResult, item.isNavigable {
                    Button {
                        onSelectResult(item)
                    } label: {
                        SearchResultRow(item: item, showsChevron: true)
                    }
                    .buttonStyle(.sparkPressable)
                    .sparkSemanticListRow()
                } else {
                    SearchResultRow(item: item, showsChevron: false)
                        .sparkSemanticListRow()
                }
            }
            .sparkSemanticListChrome()
            .refreshable {
                await viewModel.submitSearch()
            }
        }
    }
}

/// Inline results for `Tab(role: .search)` — no navigation chrome; search field lives on the tab bar.
public struct SearchTabSurfaceView: View {
    @Bindable var viewModel: SearchViewModel
    @State private var selectedPerson: SearchResultItem?
    private let onSelectResult: ((SearchResultItem) -> Void)?
    private let onOpenPersonMessages: ((String) -> Void)?

    public init(
        viewModel: SearchViewModel,
        onSelectResult: ((SearchResultItem) -> Void)? = nil,
        onOpenPersonMessages: ((String) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onSelectResult = onSelectResult
        self.onOpenPersonMessages = onOpenPersonMessages
    }

    private var hasQuery: Bool {
        !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        NavigationStack {
            Group {
                if hasQuery {
                    SearchResultsList(
                        viewModel: viewModel,
                        selectedPerson: $selectedPerson,
                        onSelectResult: onSelectResult
                    )
                } else {
                    Color.clear
                }
            }
            .modifier(SearchTabQueryModifier(viewModel: viewModel))
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(item: $selectedPerson) { person in
                SearchPersonProfileView(item: person, onOpenMessages: onOpenPersonMessages)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct SearchTabQueryModifier: ViewModifier {
    @Bindable var viewModel: SearchViewModel

    func body(content: Content) -> some View {
        content
            .searchable(
                text: $viewModel.query,
                prompt: Text(
                    String(
                        localized: "search.placeholder",
                        defaultValue: "搜索 Spark",
                        comment: "Search placeholder"
                    )
                )
            ) {
                ForEach(viewModel.searchHistory, id: \.self) { term in
                    Text(term).searchCompletion(term)
                }
                ForEach(SearchViewModel.defaultSuggestions, id: \.self) { term in
                    Text(term).searchCompletion(term)
                }
            }
            .onSubmit(of: .search) {
                Task { await viewModel.submitSearch() }
            }
            .onChange(of: viewModel.query) { _, newValue in
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    viewModel.clearResults()
                }
            }
            .task(id: viewModel.query) {
                let trimmed = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                await viewModel.submitSearch()
            }
    }
}

struct SearchResultRow: View {
    let item: SearchResultItem
    let showsChevron: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text((item.resultKind?.localizedLabel ?? item.kind).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.subtitle)")
        .accessibilityHint(item.navigationAccessibilityHint)
    }
}

extension SearchResultItem {
    var isNavigable: Bool {
        resultKind?.supportsInAppNavigation == true
    }

    var navigationAccessibilityHint: String {
        switch resultKind {
        case .activity:
            String(
                localized: "search.result.hint.activity",
                defaultValue: "在活动标签页中打开",
                comment: "Search result opens activity tab"
            )
        case .community:
            String(
                localized: "search.result.hint.community",
                defaultValue: "在社区标签页中打开",
                comment: "Search result opens community tab"
            )
        case .person, .none:
            String(
                localized: "search.result.hint.person",
                defaultValue: "查看用户资料",
                comment: "Search result person hint"
            )
        }
    }
}

#Preview("Search tab surface") {
    SearchTabSurfaceView(viewModel: SearchViewModel(repository: MockSearchRepository()))
}
