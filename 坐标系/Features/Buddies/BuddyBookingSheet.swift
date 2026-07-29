//
//  BuddyBookingSheet.swift
//  坐标系
//

import SwiftUI

struct BuddyBookingSheet: View {
    let companion: PaidCompanion
    var onBooked: (_ scheduledAt: Date, _ hours: Int, _ slotLabel: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSlot: String?
    @State private var useCustomTime = false
    @State private var scheduledAt = Date.now.addingTimeInterval(60 * 60 * 24)
    @State private var hours = 2

    private var bookableSlots: [String] {
        companion.scheduleSlots.filter(BuddyScheduleSlot.isBookable)
    }

    private var totalPrice: Int {
        companion.hourlyPrice * hours
    }

    private var resolvedStart: Date {
        if useCustomTime {
            return scheduledAt
        }
        if let selectedSlot {
            return BuddyScheduleSlot.resolveDate(from: selectedSlot)
        }
        return scheduledAt
    }

    private var canSubmit: Bool {
        companion.isAvailable
            && (useCustomTime || selectedSlot != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
                        HStack {
                            Text(companion.profile.nickname)
                                .font(.headline)
                            if companion.isVerified {
                                Text("认证")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(PlatformStatus.success.opacity(0.15), in: Capsule())
                                    .foregroundStyle(PlatformStatus.success)
                            }
                        }
                        Text(companion.specialty)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(companion.priceText) · \(companion.responseTime) 回复")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                }

                if !bookableSlots.isEmpty, !useCustomTime {
                    Section {
                        ForEach(bookableSlots, id: \.self) { slot in
                            Button {
                                selectedSlot = slot
                            } label: {
                                HStack {
                                    Label(slot, systemImage: "clock")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedSlot == slot {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            .accessibilityAddTraits(selectedSlot == slot ? .isSelected : [])
                        }
                    } header: {
                        Text("可选档期")
                    } footer: {
                        Text("先点选档期；提交后等待陪玩确认，再支付。")
                    }
                }

                Section {
                    Toggle("自定义时间", isOn: $useCustomTime)
                    if useCustomTime {
                        DatePicker(
                            "开始时间",
                            selection: $scheduledAt,
                            in: Date.now...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                    Stepper(value: $hours, in: 1...8) {
                        LabeledContent("时长", value: "\(hours) 小时")
                    }
                } header: {
                    Text(useCustomTime || bookableSlots.isEmpty ? "预约时间" : "时长")
                }

                Section("确认信息") {
                    LabeledContent("服务类型", value: companion.serviceType.rawValue)
                    LabeledContent("费用合计", value: "¥\(totalPrice)")
                    LabeledContent("档期状态", value: companion.isAvailable ? "可预约" : "暂不可约")
                    if let selectedSlot, !useCustomTime {
                        LabeledContent("已选档期", value: selectedSlot)
                    }
                }
            }
            .navigationTitle("预约陪玩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("提交预约") {
                        onBooked(
                            resolvedStart,
                            hours,
                            useCustomTime ? nil : selectedSlot
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSubmit)
                }
            }
            .onAppear {
                selectedSlot = bookableSlots.first
            }
        }
        .platformSheet(.browser)
    }
}
