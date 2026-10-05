//
//  ProfileLifePhotosGrid.swift
//  坐标系
//
//  「我的」根生活照片墙：Ins / Facebook 式三列方格 + 官方 PhotosPicker；选完即写入本机资料。
//

import CoordinateModels
import PhotosUI
import SwiftUI
import UIKit

/// 「我的」根 List 内嵌的可编辑照片墙（即时保存，不进个人资料 Form）。
struct ProfileLifePhotosGrid: View {
    @Environment(AppModel.self) private var app

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isPreparing = false
    @State private var moderationAlert: String?

    /// Ins 式细缝三列（系统 LazyVGrid + PhotosPicker）。
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: PlatformMetrics.hairlineSpacing),
        count: 3
    )

    private var names: [String] { app.user.galleryLocalNames }

    private var canAdd: Bool {
        names.count < ProfileGalleryLimits.maxCount
    }

    var body: some View {
        Group {
            if names.isEmpty, !isPreparing {
                emptyChrome
            } else {
                gridChrome
            }
        }
        .platformFeedbackAlert($moderationAlert)
        .onChange(of: pickerItems) { _, items in
            Task { await importPickerItems(items) }
        }
    }

    private var emptyChrome: some View {
        ContentUnavailableView {
            Label(ProfileGalleryCopy.emptyDetail, systemImage: "photo.on.rectangle.angled")
        } description: {
            Text(ProfileGalleryCopy.emptyHint)
        } actions: {
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: ProfileGalleryLimits.maxCount,
                matching: LocalMediaLibrary.photosAndVideos,
                photoLibrary: .shared()
            ) {
                Text(ProfileGalleryCopy.addAccessibility)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformConversationListRow.verticalInset)
    }

    private var gridChrome: some View {
        LazyVGrid(columns: columns, spacing: PlatformMetrics.hairlineSpacing) {
            ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                ProfileGalleryThumb(localName: name, usesMediaShape: false)
                    .contextMenu {
                        Button(ProfileGalleryCopy.removeAccessibility, role: .destructive) {
                            remove(at: index)
                        }
                    }
                    .accessibilityLabel(ProfileGalleryCopy.itemAccessibility(index: index + 1))
                    .accessibilityHint(ProfileGalleryCopy.removeAccessibility)
            }

            if canAdd {
                // PhotosPicker label 为 Sendable 闭包：勿直接读 @State。
                let preparing = isPreparing
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: ProfileGalleryLimits.maxCount - names.count,
                    matching: LocalMediaLibrary.photosAndVideos,
                    photoLibrary: .shared()
                ) {
                    ZStack {
                        Rectangle()
                            .fill(.quaternary.opacity(0.55))
                        if preparing {
                            ProgressView()
                        } else {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .disabled(isPreparing)
                .accessibilityLabel(ProfileGalleryCopy.addAccessibility)
            }
        }
    }

    private func remove(at index: Int) {
        guard names.indices.contains(index) else { return }
        var next = names
        let removed = next.remove(at: index)
        LocalMediaLibrary.delete(named: removed)
        commit(next)
    }

    @MainActor
    private func importPickerItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isPreparing = true
        defer {
            isPreparing = false
            pickerItems = []
        }
        var next = names
        for item in items {
            guard next.count < ProfileGalleryLimits.maxCount else { break }
            guard let name = await LocalMediaLibrary.savePickerItem(item),
                  let url = LocalMediaLibrary.fileURL(named: name)
            else { continue }
            if !LocalMediaLibrary.isVideo(url: url),
               let data = try? Data(contentsOf: url) {
                let decision = await MediaModerationService.moderateImageData(
                    data,
                    context: .community,
                    actorKey: app.user.name
                )
                if case .block(let reason) = decision {
                    LocalMediaLibrary.delete(named: name)
                    moderationAlert = reason
                    continue
                }
            }
            next.append(name)
        }
        commit(next)
    }

    private func commit(_ next: [String]) {
        var updated = app.user
        updated.galleryLocalNames = ProfileGalleryLimits.clamped(next)
        app.updateProfile(updated)
    }
}
