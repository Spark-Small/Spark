// Module: SparkSearch — Search tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct SearchRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var viewModel: SearchViewModel
    private let onSelectResult: ((SearchResultItem) -> Void)?

    public init(
        coordinator: SearchCoordinator,
        initialQuery: String = "",
        onSelectResult: ((SearchResultItem) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: coordinator.makeViewModel(initialQuery: initialQuery))
        self.onSelectResult = onSelectResult
    }

    public init(
        viewModel: SearchViewModel,
        onSelectResult: ((SearchResultItem) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectResult = onSelectResult
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        SparkScreenContainer(
            navigationTitle: String(localized: "screen.search", defaultValue: "搜索", comment: "Search screen")
        ) {
            Group {
                if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    suggestionsList
                } else {
                    resultsContent
                }
            }
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(
                    String(localized: "search.placeholder", defaultValue: "搜索 Spark", comment: "Search placeholder")
                )
            )
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
            .scrollDismissesKeyboard(.interactively)
            .modifier(SearchReadableWidthModifier(horizontalSizeClass: horizontalSizeClass))
        }
    }

    private var suggestionsList: some View {
        List {
            Section {
                ForEach(Array(SearchViewModel.defaultSuggestions.enumerated()), id: \.offset) { _, suggestion in
                    Button {
                        viewModel.query = suggestion
                    } label: {
                        Label(suggestion, systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 44)
                }
            } header: {
                Text(
                    String(localized: "search.suggestions.title", defaultValue: "建议", comment: "Search section")
                )
            }
        }
        .sparkScreenListStyle()
    }

    @ViewBuilder
    private var resultsContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "search.error.title", defaultValue: "搜索失败", comment: "Search error"),
                description: message
            ) {
                Task { await viewModel.submitSearch() }
            }
        case .loaded:
            List(viewModel.results) { item in
                if let onSelectResult, item.isNavigable {
                    Button {
                        onSelectResult(item)
                    } label: {
                        SearchResultRow(item: item, showsChevron: true)
                    }
                    .buttonStyle(.sparkPressable)
                } else {
                    SearchResultRow(item: item, showsChevron: false)
                }
            }
            .sparkScreenListStyle()
            .refreshable {
                await viewModel.submitSearch()
            }
        }
    }
}

private struct SearchReadableWidthModifier: ViewModifier {
    let horizontalSizeClass: UserInterfaceSizeClass?

    func body(content: Content) -> some View {
        if SparkAdaptiveLayout.usesSplit(horizontalSizeClass: horizontalSizeClass) {
            content.sparkReadableWidth()
        } else {
            content
        }
    }
}

private extension SearchResultItem {
    var isNavigable: Bool {
        resultKind?.supportsInAppNavigation == true
    }
}

private struct SearchResultRow: View {
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
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.subtitle)")
        .accessibilityHint(item.navigationAccessibilityHint)
    }
}

private extension SearchResultItem {
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

#Preview {
    SearchRootView(coordinator: SearchCoordinator(repository: MockSearchRepository()))
}

#Preview("Search — dark") {
    SparkPreviewSupport.darkMode {
        SearchRootView(coordinator: SearchCoordinator(repository: MockSearchRepository()))
    }
}

#Preview("Search — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        SearchRootView(coordinator: SearchCoordinator(repository: MockSearchRepository()))
    }
}

#Preview("Search — iPad regular") {
    SparkPreviewSupport.iPadRegular {
        SearchRootView(coordinator: SearchCoordinator(repository: MockSearchRepository()))
    }
}
