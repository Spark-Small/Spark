//
//  CommunityShareSheet.swift
//  坐标系
//
//  转发 / 分享联系人 / 系统分享。
//

import SwiftUI
import UIKit
import CoordinateModels

struct CommunityShareSheet: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var sentNames: Set<String> = []
    @State private var showStartChat = false
    @State private var showQuoteComposer = false
    @State private var quoteDraft = ""
    @State private var showRepostDetail = false
    @State private var didCopyLink = false
    @State private var showSystemShare = false

    private var isReposted: Bool { model.isReposted(postID) }

    private var deepLink: String {
        "zuobiaoxi://community/\(postID.uuidString)"
    }

    private var sharePayload: String {
        model.post(id: postID)?.shareText ?? deepLink
    }

    private var recipients: [DiscoverBuddyItem] {
        CommunityShareRecipients.filtered(from: buddies, query: query)
    }

    var body: some View {
        MessagesFormSheet(title: CommunitySheetCopy.shareTitle) {
            List {
                Section {
                    Button {
                        showStartChat = true
                    } label: {
                        Label(CommunitySheetCopy.startChat, systemImage: "person.badge.plus")
                    }
                }

                Section(CommunitySheetCopy.sendToSection) {
                    if recipients.isEmpty {
                        Text(query.isEmpty ? CommunitySheetCopy.noContacts : CommunitySheetCopy.noMatch)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recipients) { buddy in
                            recipientRow(buddy)
                        }
                    }
                }

                Section(CommunitySheetCopy.moreSection) {
                    Button {
                        if !isReposted {
                            model.createRepost(of: postID, quote: nil)
                        }
                        showRepostDetail = true
                    } label: {
                        Label(
                            isReposted
                                ? CommunitySheetCopy.viewRepost
                                : CommunitySheetCopy.repostToCommunity,
                            systemImage: "arrow.2.squarepath"
                        )
                    }

                    Button {
                        showQuoteComposer = true
                    } label: {
                        Label(CommunitySheetCopy.quoteRepost, systemImage: "text.quote")
                    }

                    Button {
                        UIPasteboard.general.string = deepLink
                        model.recordShare(postID)
                        didCopyLink = true
                    } label: {
                        Label(
                            didCopyLink ? CommunitySheetCopy.linkCopied : CommunitySheetCopy.copyLink,
                            systemImage: didCopyLink ? "checkmark" : "link"
                        )
                    }

                    Button {
                        model.recordShare(postID)
                        showSystemShare = true
                    } label: {
                        Label(CommunitySheetCopy.shareToSystem, systemImage: "square.and.arrow.up")
                    }
                }
            }
            .searchable(text: $query, prompt: CommunitySheetCopy.searchContactsPrompt)
            .sheet(isPresented: $showStartChat) {
                StartChatSheet { conversationID in
                    showStartChat = false
                    dismiss()
                    app.openMessages(conversationID: conversationID)
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $showQuoteComposer) {
                quoteComposer
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $showRepostDetail) {
                CommunityRepostDetailSheet(originalID: postID)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $showSystemShare) {
                PlatformShareSheet(items: [sharePayload])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }

    private func recipientRow(_ buddy: DiscoverBuddyItem) -> some View {
        let name = buddy.profile.nickname
        let sent = sentNames.contains(name)
        return Button {
            guard !sent, app.shareCommunityPost(postID, to: name) != nil else { return }
            sentNames.insert(name)
        } label: {
            Label {
                HStack {
                    Text(name)
                    Spacer(minLength: 0)
                    if sent {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)
                    }
                }
            } icon: {
                PlatformListAvatarView(
                    name: name,
                    side: PlatformConversationListRow.imageSide
                )
            }
        }
        .disabled(sent)
        .accessibilityLabel(sent ? CommunitySheetCopy.sentTo(name) : CommunitySheetCopy.sendTo(name))
    }

    private var quoteComposer: some View {
        NavigationStack {
            Form {
                TextField(CommunitySheetCopy.quotePlaceholder, text: $quoteDraft, axis: .vertical)
                    .platformFormTextInput(.body)
            }
            .navigationTitle(CommunitySheetCopy.quoteRepostTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CommunitySheetCopy.cancel) { showQuoteComposer = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CommunitySheetCopy.publish) {
                        model.createRepost(of: postID, quote: quoteDraft)
                        quoteDraft = ""
                        showQuoteComposer = false
                        showRepostDetail = true
                    }
                    .fontWeight(.semibold)
                    .disabled(quoteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .platformSheet(.form)
    }
}

@MainActor
enum CommunityShareRecipients {
    /// 仅本机搭子目录；空则诚实「暂无联系人」，禁止 Sample 灌入。
    static func filtered(from buddies: BuddiesModel, query: String) -> [DiscoverBuddyItem] {
        let pooled = buddies.freeItems + buddies.paidItems

        var seenIDs = Set<UUID>()
        var seenNicks = Set<String>()
        var unique: [DiscoverBuddyItem] = []
        for item in pooled {
            let nick = item.profile.nickname.lowercased()
            guard seenIDs.insert(item.id).inserted else { continue }
            guard seenNicks.insert(nick).inserted else { continue }
            unique.append(item)
        }
        unique.sort {
            $0.profile.nickname.localizedStandardCompare($1.profile.nickname) == .orderedAscending
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return unique }
        return unique.filter {
            $0.profile.nickname.localizedCaseInsensitiveContains(trimmed)
                || $0.profile.tags.contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }
}
