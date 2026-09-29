//
//  CommunityPhotoViewer.swift
//  坐标系
//
//  系统 Quick Look：`.quickLookPreview(_:in:)`（照片缩放 / 视频播放由系统提供）。
//

import QuickLook
import SwiftUI
import CoordinateModels

extension View {
    func communityQuickLook(_ destination: Binding<CommunityPhotoDestination?>) -> some View {
        modifier(CommunityQuickLookModifier(destination: destination))
    }
}

private struct CommunityQuickLookModifier: ViewModifier {
    @Binding var destination: CommunityPhotoDestination?
    @State private var items: [URL] = []
    @State private var selection: URL?

    func body(content: Content) -> some View {
        content
            .quickLookPreview($selection, in: items)
            .task(id: destination?.id) {
                await syncPreview()
            }
            .onChange(of: selection) { _, url in
                if url == nil {
                    destination = nil
                }
            }
    }

    @MainActor
    private func syncPreview() async {
        guard let destination else {
            selection = nil
            items = []
            return
        }

        let prepared = await CommunityQuickLookExport.prepare(destination.photos)
        items = prepared.urls
        guard !prepared.urls.isEmpty else {
            selection = nil
            self.destination = nil
            return
        }

        let mapped = prepared.indexByOriginal[destination.startIndex] ?? 0
        let start = min(max(mapped, 0), prepared.urls.count - 1)
        selection = prepared.urls[start]
    }
}

private enum CommunityQuickLookExport {
    struct Prepared {
        var urls: [URL]
        var indexByOriginal: [Int: Int]
    }

    static func prepare(_ refs: [CommunityPhotoRef]) async -> Prepared {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommunityQuickLook", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        var urls: [URL] = []
        var indexByOriginal: [Int: Int] = [:]
        for (index, ref) in refs.enumerated() {
            guard let url = await fileURL(for: ref, index: index, folder: folder) else { continue }
            indexByOriginal[index] = urls.count
            urls.append(url)
        }
        return Prepared(urls: urls, indexByOriginal: indexByOriginal)
    }

    private static func fileURL(for ref: CommunityPhotoRef, index: Int, folder: URL) async -> URL? {
        switch ref {
        case .file(let url):
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        case .asset(let name):
            guard let image = UIImage(named: name) else { return nil }
            return writeJPEG(image, name: "\(index)", folder: folder)
        case .remote(let url):
            if url.isFileURL {
                return FileManager.default.fileExists(atPath: url.path) ? url : nil
            }
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
            let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let dest = folder.appendingPathComponent("\(index).\(ext)")
            do {
                try data.write(to: dest, options: .atomic)
                return dest
            } catch {
                return nil
            }
        case .seeded(let seed, let symbol):
            guard let image = await renderSeeded(seed: seed, symbol: symbol) else { return nil }
            return writeJPEG(image, name: "\(index)", folder: folder)
        }
    }

    @MainActor
    private static func renderSeeded(seed: Int, symbol: String) -> UIImage? {
        let renderer = ImageRenderer(
            content: SeededSceneFill(seed: seed, symbol: symbol)
                .frame(width: 1200, height: 1200)
        )
        renderer.scale = 2
        return renderer.uiImage
    }

    private static func writeJPEG(_ image: UIImage, name: String, folder: URL) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let dest = folder.appendingPathComponent("\(name).jpg")
        do {
            try data.write(to: dest, options: .atomic)
            return dest
        } catch {
            return nil
        }
    }
}
