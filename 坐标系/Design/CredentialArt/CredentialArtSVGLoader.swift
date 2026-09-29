//
//  CredentialArtSVGLoader.swift
//  坐标系
//
//  从 Bundle 加载 CredentialArt SVG 模板并注入主题色。
//

import Foundation

enum CredentialArtSVGLoader {
    static func tintedData(resourceName: String, theme: CredentialArtTheme) -> Data? {
        guard let raw = loadSVGText(resourceName: resourceName) else { return nil }
        let tinted = raw
            .replacingOccurrences(of: "ACCENT_PRIMARY", with: theme.accentHex)
            .replacingOccurrences(of: "ACCENT_MUTED", with: theme.accentMutedHex)
        return tinted.data(using: .utf8)
    }

    private static func loadSVGText(resourceName: String) -> String? {
        let subdirectories = [
            "Resources/CredentialArt",
            "CredentialArt"
        ]
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: "svg",
                subdirectory: subdirectory
            ),
               let text = try? String(contentsOf: url, encoding: .utf8) {
                return text
            }
        }
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "svg"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return nil
    }
}
