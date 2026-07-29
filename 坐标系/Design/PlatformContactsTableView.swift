//
//  PlatformContactsTableView.swift
//  坐标系
//
//  通讯录：UITableView 原生 sectionIndex + 整行 UIListContentConfiguration.cell()。
//  无分隔线；头像为 person.crop.circle.fill（可叠在线点）。
//

import SwiftUI
import UIKit

struct PlatformContactsTableSection: Hashable {
    /// 分节显示字母（与 `UILocalizedIndexedCollation.sectionTitles` 一致）
    var title: String
    /// 在完整 collation `sectionTitles` 中的下标（供 sectionIndex 映射）
    var collationIndex: Int
    var items: [PlatformContactsTableItem]
}

struct PlatformContactsTableItem: Hashable {
    /// 稳定 id（通常为昵称小写）
    var id: String
    /// 打开会话 / 资料用的原始昵称
    var nickname: String
    var displayName: String
    var isActive: Bool
}

struct PlatformContactsTableView: UIViewControllerRepresentable {
    var sections: [PlatformContactsTableSection]
    var onOpenChat: (String) -> Void
    var onViewProfile: (String) -> Void

    func makeUIViewController(context: Context) -> PlatformContactsTableController {
        let controller = PlatformContactsTableController(style: .plain)
        controller.onOpenChat = onOpenChat
        controller.onViewProfile = onViewProfile
        controller.apply(sections: sections)
        return controller
    }

    func updateUIViewController(_ controller: PlatformContactsTableController, context: Context) {
        controller.onOpenChat = onOpenChat
        controller.onViewProfile = onViewProfile
        controller.apply(sections: sections)
    }
}

// MARK: - Controller

final class PlatformContactsTableController: UITableViewController {
    var onOpenChat: ((String) -> Void)?
    var onViewProfile: ((String) -> Void)?

    private var sections: [PlatformContactsTableSection] = []
    private let cellID = "platform.contacts.cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.sectionIndexColor = .secondaryLabel
        tableView.sectionIndexBackgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
    }

    func apply(sections: [PlatformContactsTableSection]) {
        let changed = self.sections != sections
        self.sections = sections
        guard isViewLoaded else { return }
        if changed {
            tableView.reloadData()
        }
    }

    // MARK: Data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.contentConfiguration = Self.listContent(for: item, traitCollection: cell.traitCollection)
        cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        cell.selectionStyle = .default
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        onOpenChat?(item.nickname)
    }

    // MARK: Native section index

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard sections.count > 1 else { return nil }
        return UILocalizedIndexedCollation.current().sectionIndexTitles
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let collation = UILocalizedIndexedCollation.current()
        let target = collation.section(forSectionIndexTitle: index)
        if let match = sections.firstIndex(where: { $0.collationIndex >= target }) {
            return match
        }
        return max(0, sections.count - 1)
    }

    // MARK: Swipe / context

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let item = sections[indexPath.section].items[indexPath.row]
        let profile = UIContextualAction(style: .normal, title: MessagesCopy.viewProfile) { [weak self] _, _, done in
            self?.onViewProfile?(item.nickname)
            done(true)
        }
        profile.image = UIImage(systemName: "person.crop.circle")
        profile.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [profile])
    }

    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let item = sections[indexPath.section].items[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let chat = UIAction(
                title: MessagesCopy.friendsListChat,
                image: UIImage(systemName: "message")
            ) { _ in
                self?.onOpenChat?(item.nickname)
            }
            let profile = UIAction(
                title: MessagesCopy.viewProfile,
                image: UIImage(systemName: "person.crop.circle")
            ) { _ in
                self?.onViewProfile?(item.nickname)
            }
            return UIMenu(children: [chat, profile])
        }
    }

    // MARK: Content configuration

    private static func resolvedImageSide(traitCollection: UITraitCollection) -> CGFloat {
        let measured = UIListContentConfiguration.ImageProperties.standardDimension
        if measured > 0 { return measured }
        return PlatformListAvatar.standardPointSize(for: DynamicTypeSize(
            uiContentSizeCategory: traitCollection.preferredContentSizeCategory
        ))
    }

    private static func listContent(
        for item: PlatformContactsTableItem,
        traitCollection: UITraitCollection
    ) -> UIListContentConfiguration {
        let side = resolvedImageSide(traitCollection: traitCollection)
        var config = UIListContentConfiguration.cell()
        config.text = item.displayName
        config.image = avatarImage(isActive: item.isActive, side: side, traitCollection: traitCollection)
        config.imageProperties.reservedLayoutSize = CGSize(width: side, height: side)
        config.imageProperties.maximumSize = CGSize(width: side, height: side)
        config.textProperties.numberOfLines = 1
        return config
    }

    /// 系统 SF Symbol 头像；在线时叠 success 色点。固定 side×side 位图，避免 list image 槽不显示。
    private static func avatarImage(
        isActive: Bool,
        side: CGFloat,
        traitCollection: UITraitCollection
    ) -> UIImage {
        let pointSize = max(22, (side * 0.92).rounded(.toNearestOrAwayFromZero))
        var symbolConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        symbolConfig = symbolConfig.applying(UIImage.SymbolConfiguration(traitCollection: traitCollection))

        let symbol = UIImage(systemName: "person.crop.circle.fill", withConfiguration: symbolConfig)?
            .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)

        let size = CGSize(width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = traitCollection.displayScale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            if let symbol {
                let symbolSize = symbol.size
                let scale = min(side / max(symbolSize.width, 1), side / max(symbolSize.height, 1))
                let drawSize = CGSize(width: symbolSize.width * scale, height: symbolSize.height * scale)
                let origin = CGPoint(x: (side - drawSize.width) / 2, y: (side - drawSize.height) / 2)
                symbol.draw(in: CGRect(origin: origin, size: drawSize))
            }

            guard isActive else { return }

            let dot = PlatformMetrics.messagePresenceDotSize
            let stroke = PlatformMetrics.avatarBadgeStroke
            let rect = CGRect(
                x: side - dot - stroke,
                y: stroke,
                width: dot,
                height: dot
            )
            UIColor.systemBackground.setFill()
            UIBezierPath(ovalIn: rect.insetBy(dx: -stroke / 2, dy: -stroke / 2)).fill()
            UIColor.systemGreen.setFill()
            UIBezierPath(ovalIn: rect).fill()
        }
    }
}
