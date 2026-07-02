// Module: SparkBuddy — Escrow booking sheet (package + schedule).

import SparkDesignSystem
import SparkPayments
import SwiftUI

struct BuddyBookingSheet: View {
    @Bindable var viewModel: BuddyDetailViewModel
    let listing: BuddyListing
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if !listing.packages.isEmpty {
                    Section {
                        BuddyPackagesSection(
                            packages: listing.packages,
                            selectedPackageID: $viewModel.selectedPackageID
                        )
                    } header: {
                        Text(
                            String(
                                localized: "buddy.booking.package.section",
                                defaultValue: "选择套餐",
                                comment: "Booking package section"
                            )
                        )
                    }
                }
                if SparkFeatureFlags.isBuddyEscrowPaymentEnabled {
                    Section {
                        Picker(
                            String(
                                localized: "buddy.booking.payment",
                                defaultValue: "支付方式",
                                comment: "Payment method picker"
                            ),
                            selection: Binding(
                                get: { viewModel.selectedPaymentMethod },
                                set: { viewModel.selectPaymentMethod($0) }
                            )
                        ) {
                            ForEach(BuddyPaymentMethod.allCases) { method in
                                Label(method.localizedTitle, systemImage: method.systemImage)
                                    .tag(method)
                            }
                        }
                        .pickerStyle(.inline)
                    } header: {
                        Text(
                            String(
                                localized: "buddy.booking.payment.section",
                                defaultValue: "托管支付",
                                comment: "Escrow payment section"
                            )
                        )
                    }
                }
                Section {
                    DatePicker(
                        String(
                            localized: "buddy.booking.schedule",
                            defaultValue: "预约时间",
                            comment: "Scheduled date picker"
                        ),
                        selection: $viewModel.scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } footer: {
                    if SparkFeatureFlags.isBuddyEscrowPaymentEnabled {
                        Text(
                            String(
                                localized: "buddy.booking.escrow.footer",
                                defaultValue: "付款由平台托管，服务完成后释放给陪玩。",
                                comment: "Escrow footer"
                            )
                        )
                    }
                }
                bookingStateSection
            }
            .navigationTitle(
                String(
                    localized: "buddy.booking.title",
                    defaultValue: "预约搭子",
                    comment: "Booking sheet title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        String(localized: "common.cancel", defaultValue: "取消", comment: "Cancel")
                    ) {
                        viewModel.resetBookingState()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    submitButton
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var bookingStateSection: some View {
        switch viewModel.bookingState {
        case .idle, .submitting:
            EmptyView()
        case .success(let confirmation):
            Section {
                Label(
                    String(
                        localized: "buddy.booking.success",
                        defaultValue: "订单已创建，平台托管付款中",
                        comment: "Booking success"
                    ),
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(Color.accentColor)
                if confirmation.escrowHeld {
                    Text(
                        String(
                            localized: "buddy.booking.escrow.held",
                            defaultValue: "款项已托管，服务完成后自动结算。",
                            comment: "Escrow held note"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        case .failure(let message):
            Section {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var submitButton: some View {
        switch viewModel.bookingState {
        case .success:
            Button(
                String(localized: "common.done", defaultValue: "完成", comment: "Done")
            ) {
                viewModel.resetBookingState()
                dismiss()
            }
        case .submitting:
            ProgressView()
        default:
            Button(submitBookingTitle) {
                Task { await viewModel.submitBooking(for: listing) }
            }
            .disabled(listing.packages.isEmpty && viewModel.selectedPackageID == nil)
        }
    }

    private var submitBookingTitle: String {
        if SparkFeatureFlags.isBuddyEscrowPaymentEnabled {
            String(
                localized: "buddy.booking.submit",
                defaultValue: "确认并支付",
                comment: "Submit booking"
            )
        } else {
            String(
                localized: "buddy.booking.submit.noPayment",
                defaultValue: "确认预约",
                comment: "Submit booking without escrow payment"
            )
        }
    }
}

#Preview("Buddy booking") {
    BuddyBookingSheet(
        viewModel: BuddyPreviewFactory.detailViewModel(),
        listing: BuddyListing(
            id: "buddy_city_1",
            ownerUserID: "user_buddy_city_1",
            displayName: "阿Ken",
            avatarURL: nil,
            coverURL: nil,
            headline: "城市探店",
            city: "北京",
            serviceCategory: .cityWalk,
            billingKind: .daily,
            priceAmount: 599,
            priceCurrencyCode: "CNY",
            tags: ["CityWalk"],
            rating: 4.8,
            reviewCount: 54,
            isVerified: true,
            supportsOfflineMeetup: true,
            supportsPaidCompanion: false,
            packages: [
                BuddyServicePackage(
                    id: "pkg_city_half_day",
                    title: "城市漫游",
                    durationHours: 4,
                    priceAmount: 299,
                    priceCurrencyCode: "CNY",
                    inclusions: ["本地人陪同"],
                    exclusions: ["餐饮费用"]
                )
            ]
        )
    )
}
