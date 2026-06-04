// Module: SparkDesignSystem — Shared screen chrome for tab roots and pushed flows.

import SwiftUI

/// Screen chrome: large navigation title and optional embedded `NavigationStack`.
public struct SparkScreenContainer<Content: View>: View {
    /// Whether this container owns a `NavigationStack` (tab roots) or only styles content (nested pushes).
    public enum NavigationEmbedding: Sendable {
        case navigationStack
        case none
    }

    let navigationTitle: String
    let embedding: NavigationEmbedding
    @ViewBuilder var content: () -> Content

    public init(
        navigationTitle: String,
        embedding: NavigationEmbedding = .navigationStack,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.navigationTitle = navigationTitle
        self.embedding = embedding
        self.content = content
    }

    public var body: some View {
        switch embedding {
        case .navigationStack:
            NavigationStack {
                styledContent
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        case .none:
            styledContent
        }
    }

    private var styledContent: some View {
        content()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Root list styling

extension View {
    /// Applies to `List` directly for consistent plain list presentation.
    public func sparkScreenListStyle() -> some View {
        listStyle(.plain)
            .listRowSeparator(.visible)
            .scrollContentBackground(.visible)
            .listRowBackground(Color.clear)
    }
}

#Preview("Screen container") {
    SparkScreenContainer(navigationTitle: "活动") {
        List {
            Text("Row")
        }
        .sparkScreenListStyle()
    }
}

#Preview("Screen container — Dark") {
    SparkScreenContainer(navigationTitle: "活动") {
        List {
            Text("Row")
        }
        .sparkScreenListStyle()
    }
    .preferredColorScheme(.dark)
}
