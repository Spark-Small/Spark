//
//  TrustSafetyCheckInSheet.swift
//  坐标系
//
//  履约后私密安全确认。
//

import SwiftUI

struct TrustSafetyCheckInSheet: View {
    let record: BuddyBookingRecord
    var onDone: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("陪玩", value: record.companionNickname)
                    LabeledContent("时长", value: "\(record.hours) 小时")
                } footer: {
                    Text("确认只写入你的行为信用，不会生成公开评价。")
                }

                Section {
                    Button {
                        submit(wentWell: true)
                    } label: {
                        Label("顺利完成", systemImage: "checkmark.circle.fill")
                    }

                    Button(role: .destructive) {
                        submit(wentWell: false)
                    } label: {
                        Label("不太顺利，需要留意", systemImage: "exclamationmark.triangle")
                    }
                } header: {
                    Text("这次履约如何？")
                }
            }
            .navigationTitle("履约确认")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("稍后") {
                        onDone()
                        dismiss()
                    }
                }
            }
        }
        .platformSheet(.form)
    }

    private func submit(wentWell: Bool) {
        TrustService.shared.submitSafetyCheckIn(
            actorKey: app.user.name,
            companionNickname: record.companionNickname,
            bookingID: record.id,
            wentWell: wentWell
        )
        onDone()
        dismiss()
    }
}
