//
//  BuddyFilterSheet+Sections.swift
//  坐标系
//
//  深筛选表单分区：地区、距离、兴趣（服务类型 / 俱乐部主题在 L1 Menu）。
//

import SwiftUI
import CoordinateModels

extension BuddyFilterSheet {
    // MARK: - Sections

    var regionSection: some View {
        Section {
            regionSectionContent
        } header: {
            Text(BuddyFilterCopy.regionHeader)
        } footer: {
            Text(BuddyFilterCopy.regionFooter)
        }
    }

    @ViewBuilder
    var regionSectionContent: some View {
        Button {
            draftUsesSystemLocation = true
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                        Text(BuddyFilterCopy.useLocation)
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
        .accessibilityLabel(BuddyFilterCopy.useLocation)
        .accessibilityValue(locationSubtitle)
        .accessibilityAddTraits(draftUsesSystemLocation ? .isSelected : [])

        if needsLocationPermission {
            Button(BuddyFilterCopy.openLocationSettings, systemImage: "gear") {
                onOpenSettings()
            }
        }

        NavigationLink(value: BuddyFilterRoute.provinces) {
            HStack {
                Label(BuddyFilterCopy.pickCity, systemImage: "building.2")
                    .platformContentSymbolStyle()
                Spacer()
                Text(citySummary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityLabel(BuddyFilterCopy.pickCity)
        .accessibilityValue(citySummary)
    }

    var distanceSection: some View {
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
                .accessibilityLabel(BuddyFilterCopy.distanceHeader)
                .accessibilityValue(distanceValueCaption)

                HStack {
                    Text(BuddyFilterCopy.distanceNear)
                    Spacer()
                    Text(BuddyFilterCopy.distanceFar)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        } header: {
            Text(BuddyFilterCopy.distanceHeader)
        } footer: {
            Text(BuddyFilterCopy.distanceFooter)
        }
    }

    var intentSection: some View {
        Section {
            ForEach(ProfileIntent.allCases) { intent in
                let selected = draftIntents.contains(intent)
                Button {
                    if selected {
                        draftIntents.remove(intent)
                    } else {
                        draftIntents.insert(intent)
                    }
                } label: {
                    HStack {
                        Text(intent.rawValue)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Button {
                draftIntents = []
            } label: {
                Text(BuddyFilterCopy.intentAny)
            }
        } header: {
            Text(BuddyFilterCopy.intentHeader)
        } footer: {
            Text(BuddyFilterCopy.intentFooter)
        }
    }

    var hobbySection: some View {
        Section {
            NavigationLink(value: BuddyFilterRoute.hobbies) {
                HStack {
                    Label(BuddyFilterCopy.hobbyHeader, systemImage: "heart")
                        .platformContentSymbolStyle()
                    Spacer()
                    Text(hobbySummary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .accessibilityLabel(BuddyFilterCopy.hobbyHeader)
            .accessibilityValue(hobbySummary)
        } header: {
            Text(BuddyFilterCopy.hobbyHeader)
        } footer: {
            Text(BuddyFilterCopy.hobbyFooter)
        }
    }

    var provinceList: some View {
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
                Text(BuddyFilterCopy.pickProvinceHeader)
            }
        }
        .navigationTitle(BuddyFilterCopy.pickCity)
        .navigationBarTitleDisplayMode(.inline)
    }

    func cityList(for province: String) -> some View {
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

    var hobbyList: some View {
        List {
            Section {
                hobbyPickRow(nil, title: BuddyFilterCopy.hobbyAny, systemImage: "infinity")
                ForEach(BuddyHobbyOption.allCases) { hobby in
                    hobbyPickRow(
                        hobby.rawValue,
                        title: hobby.rawValue,
                        systemImage: hobby.systemImage
                    )
                }
            } header: {
                Text(BuddyFilterCopy.hobbyPickHeader)
            } footer: {
                Text(BuddyFilterCopy.hobbyPickFooter)
            }
        }
        .navigationTitle(BuddyFilterCopy.hobbyHeader)
        .navigationBarTitleDisplayMode(.inline)
    }

    func hobbyPickRow(_ value: String?, title: String, systemImage: String) -> some View {
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
}
