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
    /// 本人详情：隐藏无录入位的性别/年龄/身高等（`Project/17`）。
    var showsDemographics = true
    /// 本人：只展示已录入项（年龄 0 / 未设性别等跳过）。
    var omitUnsetDemographics = false
    /// 本人已录入性别；`nil` 且 `omitUnsetDemographics` 时不展示性别行。
    var recordedGender: BuddyGender? = nil
    /// 本人城市优先投影 `AppUser.city`。
    var cityOverride: String? = nil

    private var cityText: String {
        let override = cityOverride?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !override.isEmpty { return override }
        return profile.city
    }

    private var displayGender: BuddyGender? {
        if omitUnsetDemographics { return recordedGender }
        return showsDemographics ? profile.gender : nil
    }

    private var showsAge: Bool {
        showsDemographics && (!omitUnsetDemographics || profile.age > 0)
    }

    private var showsHeight: Bool {
        showsDemographics && (!omitUnsetDemographics || profile.heightCM > 0)
    }

    private var showsWeight: Bool {
        showsDemographics && (!omitUnsetDemographics || profile.weightKG > 0)
    }

    private var showsAvailability: Bool {
        let text = profile.availability.trimmingCharacters(in: .whitespacesAndNewlines)
        return showsDemographics && (!omitUnsetDemographics || !text.isEmpty)
    }

    var body: some View {
        if let gender = displayGender {
            LabeledContent {
                Text(gender.rawValue)
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.genderLabel, systemImage: "person.fill")
            }
        }
        if showsAge {
            LabeledContent {
                Text(BuddyDetailCopy.ageValue(profile.age))
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.ageLabel, systemImage: "numbers")
            }
        }
        if showsHeight {
            LabeledContent {
                Text(profile.heightText)
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.heightLabel, systemImage: "ruler")
            }
        }
        if showsWeight {
            LabeledContent {
                Text(profile.weightText)
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.weightLabel, systemImage: "scalemass")
            }
        }
        if !cityText.isEmpty {
            LabeledContent {
                Text(cityText)
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.cityLabel, systemImage: "mappin.and.ellipse")
            }
        }
        LabeledContent {
            Text(UserPublicID.formatDisplay(UserPublicID.code(for: profile.id)))
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.publicIDLabel, systemImage: "number")
        }
        .textSelection(.enabled)
        if showsDemographics, !omitUnsetDemographics {
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
        }
        if let occupation = profile.occupation {
            LabeledContent {
                Text(occupation.rawValue)
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.occupationLabel, systemImage: "briefcase")
            }
        }
        if let radius = profile.meetRadius {
            LabeledContent {
                Text(radius.rawValue)
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.meetRadiusLabel, systemImage: "location")
            }
        }
        let intentLine = profile.intentDisplayLine
        if !intentLine.isEmpty {
            LabeledContent {
                Text(intentLine)
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.intentLabel, systemImage: "sparkles")
            }
        }
        if showsAvailability {
            LabeledContent {
                Text(profile.availability)
            } label: {
                BuddyDetailFieldLabel(title: BuddyDetailCopy.availabilityLabel, systemImage: "calendar")
            }
        }
        if !profile.prompts.isEmpty {
            ForEach(profile.prompts) { prompt in
                LabeledContent {
                    Text(prompt.answer)
                } label: {
                    BuddyDetailFieldLabel(
                        title: ProfilePromptCatalog.title(for: prompt.promptKey),
                        systemImage: "text.quote"
                    )
                }
            }
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
        return BuddyDetailCopy.statUnavailable
    }

    private var positiveRate: String {
        guard reviewStats.total > 0 else { return BuddyDetailCopy.statUnavailable }
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

