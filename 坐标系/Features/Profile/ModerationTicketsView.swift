//
//  ModerationTicketsView.swift
//  坐标系
//
//  设置 · 举报工单列表与详情。
//

import SwiftUI
import UIKit
import CoordinateModels

struct ModerationTicketsView: View {
    @Environment(AppModel.self) private var app
    @State private var pendingDeleteID: ModerationTicket.ID?

    var body: some View {
        List {
            if app.moderationTickets.isEmpty {
                ContentUnavailableView(
                    "暂无举报",
                    systemImage: "flag",
                    description: Text("社区、活动、消息或搭子举报后会出现在这里。")
                )
            } else {
                ForEach(app.moderationTickets) { ticket in
                    NavigationLink {
                        ModerationTicketDetailView(ticketID: ticket.id)
                    } label: {
                        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                            HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                                Label(ticket.targetKind.rawValue, systemImage: ticket.targetKind.systemImage)
                                    .font(PlatformListTypography.footnote)
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 0)
                                Text(ticket.status.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(moderationStatusColor(ticket.status))
                            }
                            Text(ticket.postTitle)
                                .font(PlatformListTypography.primary)
                                .lineLimit(2)
                            Text(ticket.reason)
                                .font(PlatformListTypography.secondary)
                                .foregroundStyle(.secondary)
                            Text(Formatters.conversationListTime(from: ticket.createdAt))
                                .font(PlatformListTypography.footnote)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("删除", systemImage: "trash", role: .destructive) {
                            pendingDeleteID = ticket.id
                        }
                        #if DEBUG
                        if ticket.status.nextSimulated != nil {
                            Button("推进", systemImage: "arrow.triangle.2.circlepath") {
                                app.advanceModerationTicket(ticket.id)
                            }
                            .tint(.blue)
                        }
                        #endif
                    }
                }
            }
        }
        .navigationTitle("举报记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("删除工单？", isPresented: Binding(
            get: { pendingDeleteID != nil },
            set: { if !$0 { pendingDeleteID = nil } }
        )) {
            Button("删除", role: .destructive) {
                if let pendingDeleteID {
                    app.deleteModerationTicket(pendingDeleteID)
                }
                pendingDeleteID = nil
            }
            Button("取消", role: .cancel) {
                pendingDeleteID = nil
            }
        } message: {
            Text("删除后无法恢复，仅清除本机举报记录。")
        }
    }
}

struct ModerationTicketDetailView: View {
    let ticketID: ModerationTicket.ID
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    private var ticket: ModerationTicket? {
        app.moderationTickets.first { $0.id == ticketID }
    }

    var body: some View {
        Group {
            if let ticket {
                Form {
                    Section {
                        LabeledContent("类型", value: ticket.targetKind.rawValue)
                        LabeledContent("状态") {
                            Text(ticket.status.rawValue)
                                .foregroundStyle(moderationStatusColor(ticket.status))
                                .fontWeight(.semibold)
                        }
                        LabeledContent("对象", value: ticket.postTitle)
                        LabeledContent("原因", value: ticket.reason)
                        LabeledContent(
                            "提交",
                            value: Formatters.activityDate.string(from: ticket.createdAt)
                        )
                        if let updatedAt = ticket.updatedAt {
                            LabeledContent(
                                "更新",
                                value: Formatters.activityDate.string(from: updatedAt)
                            )
                        }
                    }

                    #if DEBUG
                    if ticket.status.nextSimulated != nil
                        || ticket.status == .received
                        || ticket.status == .reviewing {
                        Section {
                            if let next = ticket.status.nextSimulated {
                                Button("推进为「\(next.rawValue)」", systemImage: "arrow.triangle.2.circlepath") {
                                    app.advanceModerationTicket(ticket.id)
                                }
                            }
                            if ticket.status == .received || ticket.status == .reviewing {
                                Button("驳回工单", systemImage: "xmark.circle", role: .destructive) {
                                    app.rejectModerationTicket(ticket.id)
                                }
                            }
                        } header: {
                            Text("本地演示")
                        } footer: {
                            Text("正式产品由运营后台处置；此处可手动推进状态机。")
                        }
                    }
                    #endif

                    Section {
                        Button("删除工单", role: .destructive) {
                            confirmDelete = true
                        }
                    }
                }
            } else {
                ContentUnavailableView("工单不存在", systemImage: "flag")
                    .onAppear { dismiss() }
            }
        }
        .navigationTitle("工单详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("删除工单？", isPresented: $confirmDelete) {
            Button("删除", role: .destructive) {
                app.deleteModerationTicket(ticketID)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复，仅清除本机举报记录。")
        }
    }
}

