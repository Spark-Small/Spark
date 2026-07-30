//
//  BuddyFilterSheet.swift
//  坐标系
//
//  搭子筛选：地区 / 性别 / 距离滑条 / 兴趣（二级列表）/ 可约，同一 Form 内完成。
//

import SwiftUI

struct BuddyFilterSheet: View {
    @Binding var filter: BuddyFilter
    @Binding var usesSystemLocation: Bool
    @Binding var selectedCityID: String
    var locatedPlaceName: String?
    var needsLocationPermission: Bool
    var onUseSystemLocation: () -> Void
    var onOpenSettings: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    @State private var draftGender: BuddyGender?
    @State private var draftMaxDistanceKM = BuddyFilterDistance.maximumKilometers
    @State private var draftHobby: String?
    @State private var draftAvailableOnly = false
    @State private var draftUsesSystemLocation = true
    @State private var draftSelectedCityID = BuddyCityCatalog.default.id

    private var draftCity: BuddyCityChoice {
        BuddyCityCatalog.city(id: draftSelectedCityID) ?? BuddyCityCatalog.default
    }

    private var hobbySummary: String {
        draftHobby ?? "不限"
    }

    private var citySummary: String {
        draftUsesSystemLocation ? "未指定" : draftCity.menuTitle
    }

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                regionSection
                genderSection
                distanceSection
                hobbySection
                availabilitySection
            }
            .navigationTitle("筛选")
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
                    Button("重置") { resetDraft() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
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

    // MARK: - Sections

    private var regionSection: some View {
        Section {
            Button {
                draftUsesSystemLocation = true
            } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                            Text("使用定位")
                            Text(locationSubtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "location.fill")
                    }
                    Spacer()
                    if draftUsesSystemLocation {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .accessibilityLabel("使用定位")
            .accessibilityValue(locationSubtitle)
            .accessibilityAddTraits(draftUsesSystemLocation ? .isSelected : [])

            if needsLocationPermission {
                Button("打开定位设置", systemImage: "gear") {
                    onOpenSettings()
                }
            }

            NavigationLink(value: BuddyFilterRoute.provinces) {
                HStack {
                    Label("指定城市", systemImage: "building.2")
                        .platformContentSymbolStyle()
                    Spacer()
                    Text(citySummary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .accessibilityLabel("指定城市")
            .accessibilityValue(citySummary)
        } header: {
            Text("地区")
        } footer: {
            Text("默认跟随定位城市；需要跨城浏览时，再指定城市。")
        }
    }

    private var genderSection: some View {
        Section {
            genderRow(nil, title: "不限", symbol: nil)
            genderRow(.female, title: "女生", symbol: BuddyGender.female.symbol)
            genderRow(.male, title: "男生", symbol: BuddyGender.male.symbol)
        } header: {
            Text("性别")
        }
    }

    private func genderRow(_ value: BuddyGender?, title: String, symbol: String?) -> some View {
        let selected = draftGender == value
        return Button {
            draftGender = value
        } label: {
            HStack {
                if let symbol {
                    Text(symbol)
                        .foregroundStyle(value?.tint ?? .primary)
                        .frame(width: 28, alignment: .center)
                } else {
                    Image(systemName: "infinity")
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .center)
                }
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var distanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                HStack {
                    Text(distanceValueTitle)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(distanceValueCaption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: $draftMaxDistanceKM,
                    in: BuddyFilterDistance.minimumKilometers...BuddyFilterDistance.maximumKilometers,
                    step: 1
                )
                .accessibilityLabel("距离")
                .accessibilityValue(distanceValueCaption)

                HStack {
                    Text("近")
                    Spacer()
                    Text("远")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("距离")
        } footer: {
            Text("左右滑动设定可接受的最远距离。")
        }
    }

    private var hobbySection: some View {
        Section {
            NavigationLink(value: BuddyFilterRoute.hobbies) {
                HStack {
                    Label("兴趣", systemImage: "heart")
                        .platformContentSymbolStyle()
                    Spacer()
                    Text(hobbySummary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .accessibilityLabel("兴趣")
            .accessibilityValue(hobbySummary)
        } header: {
            Text("兴趣")
        } footer: {
            Text("点进去选择一项兴趣；列表含全部可选标签。")
        }
    }

    private var availabilitySection: some View {
        Section {
            availabilityRow(false, title: "不限", systemImage: "infinity")
            availabilityRow(true, title: "只看可约", systemImage: "calendar")
        } header: {
            Text("档期")
        } footer: {
            Text("「只看可约」会收紧到有档期的人。")
        }
    }

    private func availabilityRow(_ value: Bool, title: String, systemImage: String) -> some View {
        let selected = draftAvailableOnly == value
        return Button {
            draftAvailableOnly = value
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                    .platformContentSymbolStyle()
                    .foregroundStyle(.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Drill-in lists

    private var provinceList: some View {
        List {
            Section {
                ForEach(BuddyCityCatalog.provinceNames, id: \.self) { province in
                    NavigationLink(value: BuddyFilterRoute.cities(province)) {
                        HStack {
                            Text(province)
                            Spacer()
                            if !draftUsesSystemLocation, draftCity.province == province {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
            } header: {
                Text("选择省份 / 直辖市")
            }
        }
        .navigationTitle("指定城市")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cityList(for province: String) -> some View {
        let cities = BuddyCityCatalog.cities(in: province)
        return List {
            Section {
                ForEach(cities) { city in
                    Button {
                        draftUsesSystemLocation = false
                        draftSelectedCityID = city.id
                        path = NavigationPath()
                    } label: {
                        HStack {
                            Text(city.city)
                                .foregroundStyle(.primary)
                            Spacer()
                            if !draftUsesSystemLocation, draftSelectedCityID == city.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .accessibilityLabel("\(province) \(city.city)")
                    .accessibilityAddTraits(
                        (!draftUsesSystemLocation && draftSelectedCityID == city.id)
                            ? .isSelected : []
                    )
                }
            } header: {
                Text(province)
            }
        }
        .navigationTitle(province)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hobbyList: some View {
        List {
            Section {
                hobbyPickRow(nil, title: "不限", systemImage: "infinity")
                ForEach(BuddyHobbyOption.allCases) { hobby in
                    hobbyPickRow(
                        hobby.rawValue,
                        title: hobby.rawValue,
                        systemImage: hobby.systemImage
                    )
                }
            } header: {
                Text("选择兴趣")
            } footer: {
                Text("与原先筛选条相同的全部兴趣项。")
            }
        }
        .navigationTitle("兴趣")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func hobbyPickRow(_ value: String?, title: String, systemImage: String) -> some View {
        let selected = draftHobby == value
        return Button {
            draftHobby = value
            path = NavigationPath()
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                    .platformContentSymbolStyle()
                    .foregroundStyle(.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Draft

    private func loadDraft() {
        draftGender = filter.gender
        draftMaxDistanceKM = filter.maxDistanceKM.clamped(
            to: BuddyFilterDistance.minimumKilometers...BuddyFilterDistance.maximumKilometers
        )
        draftHobby = filter.hobby
        draftAvailableOnly = filter.availableOnly
        draftUsesSystemLocation = usesSystemLocation
        draftSelectedCityID = selectedCityID
    }

    private func resetDraft() {
        draftGender = nil
        draftMaxDistanceKM = BuddyFilterDistance.maximumKilometers
        draftHobby = nil
        draftAvailableOnly = false
        draftUsesSystemLocation = true
        draftSelectedCityID = BuddyCityCatalog.default.id
        path = NavigationPath()
    }

    private func applyDraft() {
        filter.gender = draftGender
        filter.maxDistanceKM = draftMaxDistanceKM
        filter.hobby = draftHobby
        filter.availableOnly = draftAvailableOnly
        usesSystemLocation = draftUsesSystemLocation
        selectedCityID = draftSelectedCityID
        if draftUsesSystemLocation {
            onUseSystemLocation()
        }
    }

    private var locationSubtitle: String {
        if let locatedPlaceName, !locatedPlaceName.isEmpty {
            return locatedPlaceName
        }
        if needsLocationPermission {
            return "未开启定位"
        }
        return "正在获取…"
    }

    private var distanceValueTitle: String {
        if draftMaxDistanceKM >= BuddyFilterDistance.maximumKilometers {
            return "不限距离"
        }
        if draftMaxDistanceKM <= 3 {
            return "附近"
        }
        if draftMaxDistanceKM <= 8 {
            return "片区"
        }
        if draftMaxDistanceKM <= 15 {
            return "同城"
        }
        return "较远"
    }

    private var distanceValueCaption: String {
        if draftMaxDistanceKM >= BuddyFilterDistance.maximumKilometers {
            return "\(Int(BuddyFilterDistance.maximumKilometers))+ km"
        }
        return "\(Int(draftMaxDistanceKM)) km"
    }
}

private enum BuddyFilterRoute: Hashable {
    case provinces
    case cities(String)
    case hobbies
}

enum BuddyFilterDistance {
    static let minimumKilometers: Double = 1
    static let maximumKilometers: Double = 20
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    @Previewable @State var filter = BuddyFilter()
    @Previewable @State var usesLocation = true
    @Previewable @State var cityID = BuddyCityCatalog.default.id
    BuddyFilterSheet(
        filter: $filter,
        usesSystemLocation: $usesLocation,
        selectedCityID: $cityID,
        locatedPlaceName: "上海",
        needsLocationPermission: false,
        onUseSystemLocation: {},
        onOpenSettings: {}
    )
}
