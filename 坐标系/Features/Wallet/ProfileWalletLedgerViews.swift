//
//  ProfileWalletLedgerViews.swift
//  坐标系
//
//  钱包账单行与「全部交易」：按月分节 + searchable（首屏只留最近几条）。
//

import CoordinateModels
import SwiftUI

struct WalletLedgerRow: View {
    let entry: WalletLedgerEntry

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            Label {
                VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(entry.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(secondaryLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } icon: {
                Image(systemName: entry.kind.systemImage)
            }
            .labelStyle(.titleAndIcon)
            .platformContentSymbolStyle()

            Spacer(minLength: PlatformMetrics.minContentGap)

            Text(amountText)
                .font(.body.monospacedDigit())
                .foregroundStyle(amountColor)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }

    private var secondaryLine: String {
        var parts: [String] = []
        if let subtitle = entry.subtitle,
           !subtitle.isEmpty,
           subtitle != WalletMoney.formatted(cents: entry.amountCents) {
            parts.append(subtitle)
        }
        parts.append(Formatters.conversationListTime(from: entry.createdAt))
        return parts.joined(separator: " · ")
    }

    private var amountText: String {
        if entry.balanceDeltaCents != 0 {
            return WalletMoney.signedFormatted(cents: entry.balanceDeltaCents)
        }
        return "-\(WalletMoney.formatted(cents: entry.amountCents))"
    }

    private var amountColor: Color {
        entry.balanceDeltaCents > 0 ? PlatformStatus.success : .primary
    }
}

struct ProfileWalletLedgerAllView: View {
    @Environment(WalletStore.self) private var wallet
    @State private var searchText = ""

    private var filteredEntries: [WalletLedgerEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return wallet.entries }
        return wallet.entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query)
                || (entry.subtitle?.localizedCaseInsensitiveContains(query) ?? false)
                || entry.kind.titleFallback.localizedCaseInsensitiveContains(query)
        }
    }

    private var monthSections: [(title: String, entries: [WalletLedgerEntry])] {
        var order: [String] = []
        var buckets: [String: [WalletLedgerEntry]] = [:]
        for entry in filteredEntries {
            let key = Formatters.yearMonthSection.string(from: entry.createdAt)
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            buckets[key]?.append(entry)
        }
        return order.map { title in
            (title, buckets[title] ?? [])
        }
    }

    var body: some View {
        List {
            if !wallet.entries.isEmpty, !filteredEntries.isEmpty {
                ForEach(monthSections, id: \.title) { section in
                    Section(section.title) {
                        ForEach(section.entries) { entry in
                            WalletLedgerRow(entry: entry)
                        }
                    }
                }
            }
        }
        .profileSecondaryListChrome()
        .overlay {
            if wallet.entries.isEmpty {
                ContentUnavailableView {
                    Label(ProfileWalletCopy.ledgerEmptyTitle, systemImage: "list.bullet.rectangle")
                } description: {
                    Text(ProfileWalletCopy.ledgerEmptyDescription)
                }
                .platformContentUnavailablePageChrome()
            } else if filteredEntries.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .platformContentUnavailablePageChrome()
            }
        }
        .searchable(text: $searchText, prompt: ProfileWalletCopy.ledgerSearchPrompt)
        .navigationTitle(ProfileWalletCopy.ledgerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await wallet.refreshFromRemoteIfEnabled()
        }
        .refreshable {
            await wallet.refreshFromRemoteIfEnabled()
        }
    }
}
