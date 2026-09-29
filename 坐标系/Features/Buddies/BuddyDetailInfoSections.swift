//
//  BuddyDetailInfoSections.swift
//  坐标系
//
//  搭子详情：基础信息 / 服务 / 表现。
//

import SwiftUI
import CoordinateModels

// MARK: - Basic info

struct BuddyDetailFieldLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
    }
}

struct BuddyDetailBasicInfoSection: View {
    let profile: BuddyProfile

    var body: some View {
        LabeledContent {
            Text(profile.gender.rawValue)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.genderLabel, systemImage: "person.fill")
        }
        LabeledContent {
            Text(BuddyDetailCopy.ageValue(profile.age))
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.ageLabel, systemImage: "numbers")
        }
        LabeledContent {
            Text(profile.heightText)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.heightLabel, systemImage: "ruler")
        }
        LabeledContent {
            Text(profile.weightText)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.weightLabel, systemImage: "scalemass")
        }
        LabeledContent {
            Text(profile.city)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.cityLabel, systemImage: "mappin.and.ellipse")
        }
        LabeledContent {
            Text(UserPublicID.formatDisplay(UserPublicID.code(for: profile.id)))
        } label: {
            BuddyDetailFieldLabel(title: "UID", systemImage: "number")
        }
            .textSelection(.enabled)
        if PrivacyPreferences.showOnline || !profile.lastActiveText.isEmpty {
            if let status = PrivacyPreferences.statusLine(
                isOnline: false,
                lastActiveText: profile.lastActiveText
            ) {
                LabeledContent {
                    Text(status)
                } label: {
                    BuddyDetailFieldLabel(title: BuddyDetailCopy.activeLabel, systemImage: "clock")
                }
            }
        }
        LabeledContent {
            Text(profile.availability)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.availabilityLabel, systemImage: "calendar")
        }
    }
}

struct BuddyDetailServiceInfoSection: View {
    let companion: PaidCompanion

    var body: some View {
        LabeledContent {
            Text(companion.serviceType.rawValue)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.serviceTypeLabel, systemImage: "square.stack.3d.up")
        }
        LabeledContent {
            Text(companion.specialty)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.specialtyLabel, systemImage: "sparkles")
        }
        LabeledContent {
            Text(companion.priceText)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.priceLabel, systemImage: "tag")
        }
        LabeledContent {
            Text(companion.profile.availability)
        } label: {
            BuddyDetailFieldLabel(
                title: companion.isAvailable ? BuddyDetailCopy.available : BuddyDetailCopy.unavailable,
                systemImage: "calendar.badge.clock"
            )
        }
    }
}

struct BuddyDetailPerformanceSection: View {
    let companion: PaidCompanion

    private var reviewStats: PlatformReviewStats {
        PlatformReviewsStore.stats(for: .companion(companion.id))
    }

    private var rating: String {
        if let average = reviewStats.averageRating {
            return String(format: "%.1f", average)
        }
        return String(format: "%.1f", PlatformReviewCatalog.displayRating(for: companion))
    }

    private var positiveRate: String {
        guard reviewStats.total > 0 else { return "98%" }
        let value = Int((Double(reviewStats.positive) / Double(reviewStats.total) * 100).rounded())
        return "\(value)%"
    }

    var body: some View {
        LabeledContent {
            Text(BuddyDetailCopy.ordersValue(companion.orderCount))
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.statOrders, systemImage: "checkmark.rectangle")
        }
        LabeledContent {
            Text(rating)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.statRating, systemImage: "star.leadinghalf.filled")
        }
        LabeledContent {
            Text(positiveRate)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.statPositiveRate, systemImage: "hand.thumbsup")
        }
        LabeledContent {
            Text(companion.responseTime)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.statResponse, systemImage: "bolt.badge.clock")
        }
    }
}

