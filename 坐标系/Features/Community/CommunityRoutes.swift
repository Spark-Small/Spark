//
//  CommunityRoutes.swift
//  坐标系
//
//  广场作者路由与呈现修饰。
//

import SwiftUI
import CoordinateModels

enum CommunityAuthorDestination: Identifiable {
    case buddy(DiscoverBuddyItem)
    case fallback(String)

    var id: String {
        switch self {
        case .buddy(let item): "buddy-\(item.id)"
        case .fallback(let name): "fallback-\(name)"
        }
    }
}

extension View {
    func communityAuthorSheet(_ destination: Binding<CommunityAuthorDestination?>) -> some View {
        sheet(item: destination) { route in
            switch route {
            case .buddy(let item):
                NavigationStack {
                    BuddyDetailRouteView(item: item)
                        .platformSheetConfirmationToolbar()
                }
                .platformSheet(.browser)
            case .fallback(let name):
                CommunityAuthorFallbackSheet(name: name)
            }
        }
    }
}

extension BuddiesModel {
    func authorDestination(for name: String) -> CommunityAuthorDestination {
        if let item = item(for: name) {
            .buddy(item)
        } else {
            .fallback(name)
        }
    }
}
