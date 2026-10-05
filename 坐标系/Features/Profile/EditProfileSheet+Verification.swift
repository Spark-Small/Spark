//
//  EditProfileSheet+Verification.swift
//  坐标系
//
//  编辑资料：认证与安全（实名 / 防欺诈 / 手机号 / 信誉）。
//

import SwiftUI
import CoordinateModels

extension EditProfileSheet {
    private var photoVerified: Bool {
        photoVerification.isVerified(for: user)
    }

    var verificationSection: some View {
        Section {
            NavigationLink {
                RealNameVerificationSheet(
                    user: $user,
                    embedsOwnNavigationChrome: false
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            } label: {
                LabeledContent {
                    Text(
                        user.isRealNameVerified
                            ? RealNameVerificationCopy.entryVerified
                            : RealNameVerificationCopy.entryUnverified
                    )
                    .foregroundStyle(user.isRealNameVerified ? PlatformStatus.success : .secondary)
                } label: {
                    Label(
                        RealNameVerificationCopy.entryTitle,
                        systemImage: user.isRealNameVerified
                            ? TrustBadgeKind.identityVerified.systemImage
                            : "person.text.rectangle"
                    )
                    .symbolRenderingMode(user.isRealNameVerified ? .multicolor : .hierarchical)
                }
            }

            NavigationLink {
                PhotoVerificationView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            } label: {
                LabeledContent {
                    Text(photoVerified ? EditProfileCopy.photoVerified : EditProfileCopy.photoUnverified)
                        .foregroundStyle(photoVerified ? PlatformStatus.success : .secondary)
                } label: {
                    Label(
                        EditProfileCopy.photoVerificationLabel,
                        systemImage: photoVerified
                            ? TrustBadgeKind.photoVerified.systemImage
                            : "camera.viewfinder"
                    )
                    .symbolRenderingMode(photoVerified ? .multicolor : .hierarchical)
                }
            }
            .accessibilityHint(
                photoVerified
                    ? EditProfileCopy.managePhotoVerification
                    : EditProfileCopy.startPhotoVerification
            )

            Button {
                showBindPhoneSheet = true
            } label: {
                LabeledContent {
                    Text(
                        app.auth.hasBoundPhone
                            ? app.auth.maskedPhoneLabel
                            : EditProfileCopy.phoneUnbound
                    )
                    .foregroundStyle(app.auth.hasBoundPhone ? PlatformStatus.success : .secondary)
                } label: {
                    Label(
                        EditProfileCopy.phoneLabel,
                        systemImage: app.auth.hasBoundPhone
                            ? TrustBadgeKind.phoneVerified.systemImage
                            : "iphone.gen3"
                    )
                    .symbolRenderingMode(app.auth.hasBoundPhone ? .multicolor : .hierarchical)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)

            NavigationLink {
                TrustPrivateDashboardView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            } label: {
                Label(EditProfileCopy.trustDashboardEntry, systemImage: "checkmark.shield.fill")
            }
        } header: {
            Text(EditProfileCopy.verificationHeader)
        }
    }
}
