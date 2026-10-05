//
//  EditProfileSheet+Sections.swift
//  坐标系
//
//  个人资料 Form 分区（Settings 序）：头 → 介绍 → 基本资料 → … → 安全 → 账号。
//

import CoordinateModels
import PhotosUI
import SwiftUI
import UIKit

extension EditProfileSheet {
    var identityHeroSection: some View {
        // 对齐 Settings「Apple 账户」头：大圆头像 + 名 + 副文。
        // 透明头区若用 Form 默认 listRowInsets，会把整块垫得过高；上下改用 subtitleCell 行 margin。
        let avatarSide = dynamicTypeSize.accountHeaderAvatarSide
        let titleSubtitleSpacing = PlatformAccountHeaderMetrics.textToSecondarySpacing
        let heroVerticalInset = PlatformConversationListRow.verticalInset
        return Section {
            VStack(spacing: titleSubtitleSpacing) {
                ZStack {
                    PlatformListAvatarView(name: name, photo: avatarPreview, side: avatarSide)
                    PhotosPicker(
                        selection: $pickerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Color.clear
                            .frame(width: avatarSide, height: avatarSide)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(isPreparingAvatar)
                    .accessibilityLabel(
                        avatarLocalName == nil
                            ? EditProfileCopy.addPhoto
                            : EditProfileCopy.changePhoto
                    )
                    .accessibilityHint(EditProfileCopy.changePhotoHint)
                }

                if avatarLocalName != nil {
                    Button(EditProfileCopy.removePhoto, role: .destructive) {
                        removeAvatar()
                    }
                    .buttonStyle(.plain)
                }

                TextField(EditProfileCopy.namePlaceholder, text: $name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .platformFormTextInput(.singleLine)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(EditProfileCopy.nameLabel)
                    .onChange(of: name) { _, value in
                        let next = ProfileEditLimits.clamped(value, max: ProfileEditLimits.nameMax)
                        if next != value { name = next }
                    }

                // 副文 = 居中账号字段（Apple 账户邮箱行气质；不另挂「@」）。
                TextField(EditProfileCopy.handlePlaceholder, text: $handle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .platformFormTextInput(.identifier)
                    .accessibilityLabel(EditProfileCopy.handleLabel)
                    .onChange(of: handle) { _, value in
                        let next = ProfileEditLimits.normalizeHandle(value)
                        if next != value { handle = next }
                    }

                if isPreparingAvatar {
                    ProgressView()
                        .controlSize(.regular)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(
                EdgeInsets(
                    top: heroVerticalInset,
                    leading: 0,
                    bottom: heroVerticalInset,
                    trailing: 0
                )
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .onChange(of: pickerItem) { _, item in
                Task { await loadAvatar(item) }
            }
        }
    }

    var demographicsSection: some View {
        Section {
            // 只读值 secondary，对齐 Settings 右侧说明（如 iCloud「5 GB」）。
            LabeledContent(EditProfileCopy.genderLabel) {
                Text(genderDisplayValue)
                    .foregroundStyle(.secondary)
            }
            LabeledContent(EditProfileCopy.ageLabel) {
                Text(ageDisplayValue)
                    .foregroundStyle(.secondary)
            }

            // 右侧数字 + 固定单位（非 Picker，无上下箭头）。
            measurementRow(
                label: EditProfileCopy.heightLabel,
                unit: EditProfileCopy.heightUnit,
                text: $heightText
            )
            measurementRow(
                label: EditProfileCopy.weightLabel,
                unit: EditProfileCopy.weightUnit,
                text: $weightText
            )

            LabeledContent(EditProfileCopy.availabilityLabel) {
                TextField(EditProfileCopy.availabilityPlaceholder, text: $availability)
                    .platformFormTextInput(.trailing)
                    .foregroundStyle(.primary)
                    .onChange(of: availability) { _, value in
                        let next = ProfileEditLimits.clamped(
                            value,
                            max: ProfileDemographicsLimits.availabilityMax
                        )
                        if next != value { availability = next }
                    }
            }

            // `>` disclosure，对齐 Apple 账户可进入行（非菜单上下箭头）。
            Picker(EditProfileCopy.occupationLabel, selection: $occupation) {
                Text(EditProfileCopy.genderUnset).tag(Optional<ProfileOccupation>.none)
                ForEach(ProfileOccupation.allCases) { value in
                    Text(value.rawValue).tag(Optional(value))
                }
            }
            .pickerStyle(.navigationLink)

            Picker(EditProfileCopy.meetRadiusLabel, selection: $meetRadius) {
                Text(EditProfileCopy.genderUnset).tag(Optional<ProfileMeetRadius>.none)
                ForEach(ProfileMeetRadius.allCases) { value in
                    Text(value.rawValue).tag(Optional(value))
                }
            }
            .pickerStyle(.navigationLink)

            Picker(EditProfileCopy.mbtiLabel, selection: $mbti) {
                Text(EditProfileCopy.genderUnset).tag(Optional<ProfileMBTI>.none)
                ForEach(ProfileMBTI.allCases) { value in
                    Text(value.rawValue).tag(Optional(value))
                }
            }
            .pickerStyle(.navigationLink)

            // 有生日：只读展示推导星座；否则系统 Picker 自选。
            if let birthDate = user.birthDate {
                LabeledContent(EditProfileCopy.zodiacLabel) {
                    Text(ProfileZodiac.from(birthDate: birthDate).rawValue)
                        .foregroundStyle(.secondary)
                }
                .accessibilityValue(EditProfileCopy.zodiacFromBirth)
            } else {
                Picker(EditProfileCopy.zodiacLabel, selection: $zodiac) {
                    Text(EditProfileCopy.genderUnset).tag(Optional<ProfileZodiac>.none)
                    ForEach(ProfileZodiac.allCases) { value in
                        Text(value.rawValue).tag(Optional(value))
                    }
                }
                .pickerStyle(.navigationLink)
            }

            LabeledContent(EditProfileCopy.uidLabel) {
                Text(user.publicUIDDisplay)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        } header: {
            Text(EditProfileCopy.demographicsHeader)
        }
    }

    /// Settings 度量行：左标签、右数字 TextField、固定单位后缀。
    private func measurementRow(
        label: String,
        unit: String,
        text: Binding<String>
    ) -> some View {
        LabeledContent(label) {
            HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                TextField(
                    EditProfileCopy.genderUnset,
                    text: Binding(
                        get: { text.wrappedValue },
                        set: { text.wrappedValue = ProfileEditLimits.digitsOnly($0, maxDigits: 3) }
                    )
                )
                .platformFormTextInput(.trailingDigits)
                Text(unit)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var genderDisplayValue: String {
        if let gender { return gender.rawValue }
        return EditProfileCopy.certifiedAutoValue
    }

    private var ageDisplayValue: String {
        if let age { return RealNameVerificationCopy.ageValue(age) }
        return EditProfileCopy.certifiedAutoValue
    }

    var aboutYouSection: some View {
        Section {
            TextField(EditProfileCopy.bioPlaceholder, text: $bio, axis: .vertical)
                // 短简介：最少 2 行（`.body` 为 3…8，空态空白偏多）。
                .platformFormTextInput(.note)
                .onChange(of: bio) { _, value in
                    let next = ProfileEditLimits.clamped(value, max: ProfileEditLimits.bioMax)
                    if next != value { bio = next }
                }

            LabeledContent(EditProfileCopy.cityLabel) {
                TextField(EditProfileCopy.cityPlaceholder, text: $city)
                    .platformFormTextInput(.trailing)
                    .foregroundStyle(.primary)
                    .onChange(of: city) { _, value in
                        let next = ProfileEditLimits.clamped(value, max: ProfileEditLimits.cityMax)
                        if next != value { city = next }
                    }
            }
        } header: {
            Text(EditProfileCopy.aboutHeader)
        }
    }

    var favoritesSection: some View {
        Section {
            NavigationLink {
                InterestTaxonomyFormEditor(selected: $selectedInterests)
            } label: {
                LabeledContent(EditProfileCopy.interestsLabel) {
                    Text(
                        selectedInterests.isEmpty
                            ? EditProfileCopy.interestsEmpty
                            : EditProfileCopy.interestsCount(selectedInterests.count)
                    )
                    .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(EditProfileCopy.interestsHeader)
        }
    }

}
