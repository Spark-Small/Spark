// Module: SparkSearch — Search tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct SearchRootView: View {
    @State private var viewModel: SearchViewModel
    @State private var selectedPerson: SearchResultItem?
    private let onSelectResult: ((SearchResultItem) -> Void)?
    private let onOpenPersonMessages: ((String) -> Void)?
    private let usesTabRoleSearchChrome: Bool

    public init(
        coordinator: SearchCoordinator,
        initialQuery: String = "",
        usesTabRoleSearchChrome: Bool = false,
        onSelectResult: ((SearchResultItem) -> Void)? = nil,
        onOpenPersonMessages: ((String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: coordinator.makeViewModel(initialQuery: initialQuery))
        self.usesTabRoleSearchChrome = usesTabRoleSearchChrome
        self.onSelectResult = onSelectResult
        self.onOpenPersonMessages = onOpenPersonMessages
    }

    public init(
        viewModel: SearchViewModel,
        usesTabRoleSearchChrome: Bool = false,
        onSelectResult: ((SearchResultItem) -> Void)? = nil,
        onOpenPersonMessages: ((String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.usesTabRoleSearchChrome = usesTabRoleSearchChrome
        self.onSelectResult = onSelectResult
        self.onOpenPersonMessages = onOpenPersonMessages
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
                    SearchResultsList(
                        viewModel: viewModel,
                        selectedPerson: $selectedPerson,
                        onSelectResult: onSelectResult
                    )
                }
            }
            .modifier(SearchQueryChromeModifier(usesTabRoleSearchChrome: usesTabRoleSearchChrome, viewModel: viewModel))
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(item: $selectedPerson) { person in
                SearchPersonProfileView(item: person, onOpenMessages: onOpenPersonMessages)
            }
        }
    }

    private var suggestionsList: some View {
        List {
            if !viewModel.searchHistory.isEmpty {
                Section {
                    ForEach(viewModel.searchHistory, id: \.self) { historyItem in
                    Button {
                        viewModel.query = historyItem
                    } label: {
                        Label(historyItem, systemImage: "clock")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.sparkPressable)
                    .sparkSemanticListRow()
                    }
                } header: {
                    HStack {
                        Text(
                            String(
                                localized: "search.history.title",
                                defaultValue: "最近搜索",
                                comment: "Search history"
                            )
                        )
                        Spacer()
                        Button(
                            String(localized: "search.history.clear", defaultValue: "清除", comment: "Clear history")
                        ) {
                            viewModel.clearSearchHistory()
                        }
                        .font(.caption)
                    }
                }
            }

            Section {
                ForEach(Array(SearchViewModel.defaultSuggestions.enumerated()), id: \.offset) { _, suggestion in
                    Button {
                        viewModel.query = suggestion
                    } label: {
                        Label(suggestion, systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.sparkPressable)
                    .sparkSemanticListRow()
                }
            } header: {
                Text(
                    String(localized: "search.suggestions.title", defaultValue: "建议", comment: "Search section")
                )
            }
        }
        .sparkSemanticListChrome()
    }
}

private struct SearchQueryChromeModifier: ViewModifier {
    let usesTabRoleSearchChrome: Bool
    @Bindable var viewModel: SearchViewModel

    func body(content: Content) -> some View {
        if usesTabRoleSearchChrome {
            content
        } else {
            content
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

