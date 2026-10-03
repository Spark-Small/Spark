//
//  BuddyFilterSheet.swift
//  坐标系
//
//  深筛选按模式分流：找搭子=地区·距离·兴趣；约陪玩=地区·距离；俱乐部=城市。
//  L1 Menu 已接管排序 / 性别 / 可约 / 服务类型 / 俱乐部主题。
//

import SwiftUI
import CoordinateModels

struct BuddyFilterSheet: View {
    @Binding var filter: BuddyFilter
    @Binding var usesSystemLocation: Bool
    @Binding var selectedCityID: String
    var locatedPlaceName: String?
    var needsLocationPermission: Bool
    var onUseSystemLocation: () -> Void
    var onOpenSettings: () -> Void

    @Environment(\.dismiss) var dismiss
    @State var path = NavigationPath()

    @State var draftMaxDistanceKM = BuddyFilterDistance.maximumKilometers
    @State var draftHobby: String?
    @State var draftUsesSystemLocation = true
    @State var draftSelectedCityID = BuddyCityCatalog.default.id

    var draftCity: BuddyCityChoice {
        BuddyCityCatalog.city(id: draftSelectedCityID) ?? BuddyCityCatalog.default
    }

    var hobbySummary: String {
        draftHobby ?? BuddyFilterCopy.hobbyAny
    }

    var citySummary: String {
        draftUsesSystemLocation ? BuddyFilterCopy.cityUnspecified : draftCity.menuTitle
    }

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                switch filter.kind {
                case .free:
                    regionSection
                    distanceSection
                    hobbySection
                case .paid:
                    regionSection
                    distanceSection
                case .clubs:
                    clubRegionSection
                }
            }
            .navigationTitle(BuddyFilterCopy.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: BuddyFilterRoute.self) { route in
                switch route {
                case .provinces:
                    provinceList
                case .cities(let province):
                    cityList(for: province)
                case .hobbies:
                    hobbyList
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BuddyFilterCopy.reset) { resetDraft() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyFilterCopy.apply) {
                        applyDraft()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { loadDraft() }
        }
        .platformSheet(.filter)
    }

    /// 俱乐部深筛：城市（无距离滑杆）。
    var clubRegionSection: some View {
        Section {
            regionSectionContent
        } header: {
            Text(BuddyFilterCopy.regionHeader)
        } footer: {
            Text(BuddyFilterCopy.clubRegionFooter)
        }
    }
}
