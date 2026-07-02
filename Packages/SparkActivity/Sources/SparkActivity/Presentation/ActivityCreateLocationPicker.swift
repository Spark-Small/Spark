// Module: SparkActivity — POI location picker (search-first, CN meetup habit).

@preconcurrency import MapKit
import SparkCore
import SparkDesignSystem
import SwiftUI

// MARK: - Models

struct ActivityCreateLocationResult: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let formattedName: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Search model

@MainActor
@Observable
final class ActivityCreateLocationSearchModel {
    var query = ""
    var results: [ActivityCreateLocationResult] = []
    var selectedResultID: String?
    var mapAnchorCoordinate: CLLocationCoordinate2D?
    var isSearching = false
    var isResolvingSelection = false
    var searchErrorMessage: String?

    private var searchTask: Task<Void, Never>?
    private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
        span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
    )

    var mapFocusCoordinate: CLLocationCoordinate2D? {
        if let selectedResultID,
           let selected = results.first(where: { $0.id == selectedResultID }) {
            return selected.coordinate
        }
        return mapAnchorCoordinate
    }

    var mapFocusTitle: String {
        if let selectedResultID,
           let selected = results.first(where: { $0.id == selectedResultID }) {
            return selected.title
        }
        return String(
            localized: "activity.create.location.map.anchor",
            defaultValue: "附近",
            comment: "Map anchor label when no POI selected"
        )
    }

    var selectedResult: ActivityCreateLocationResult? {
        guard let selectedResultID else { return nil }
        return results.first(where: { $0.id == selectedResultID })
    }

    func updateQuery(_ newValue: String) {
        query = newValue
        searchTask?.cancel()
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            selectedResultID = nil
            searchErrorMessage = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            await performSearch(trimmed)
        }
    }

    func updateRegion(to coordinate: CLLocationCoordinate2D) {
        mapAnchorCoordinate = coordinate
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
        )
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        searchTask?.cancel()
        searchTask = Task {
            await performSearch(trimmed)
        }
    }

    func selectResult(id: String) {
        selectedResultID = id
    }

    func confirmSelection() -> String? {
        selectedResult?.formattedName
    }

    private func performSearch(_ trimmedQuery: String) async {
        isSearching = true
        searchErrorMessage = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedQuery
        request.region = region
        request.resultTypes = [.pointOfInterest, .address]

        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems.compactMap(Self.makeResult(from:))
            syncSelectionAfterSearch()
        } catch is CancellationError {
            return
        } catch {
            results = []
            searchErrorMessage = String(
                localized: "activity.create.location.search.error",
                defaultValue: "地点搜索失败，请稍后再试",
                comment: "Location search error"
            )
        }
    }

    private static func makeResult(from item: MKMapItem) -> ActivityCreateLocationResult? {
        let title = item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else { return nil }

        let placemark = item.placemark
        let subtitleParts = [
            placemark.thoroughfare,
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea,
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .reduce(into: [String]()) { partial, value in
            if !partial.contains(value) { partial.append(value) }
        }

        let subtitle = subtitleParts.joined(separator: " ")
        let formattedName = formattedLocationName(from: item, fallbackTitle: title)
        let id = [title, subtitle, formattedName].joined(separator: "|")
        guard CLLocationCoordinate2DIsValid(placemark.coordinate) else { return nil }

        return ActivityCreateLocationResult(
            id: id,
            title: title,
            subtitle: subtitle,
            formattedName: formattedName,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude
        )
    }

    private func syncSelectionAfterSearch() {
        guard !results.isEmpty else {
            selectedResultID = nil
            return
        }
        if let selectedResultID,
           results.contains(where: { $0.id == selectedResultID }) {
            return
        }
        selectedResultID = results.first?.id
    }

    static func formattedLocationName(from item: MKMapItem, fallbackTitle: String) -> String {
        let trimmedName = item.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (trimmedName?.isEmpty == false) ? trimmedName ?? fallbackTitle : fallbackTitle

        let placemark = item.placemark
        let district = [placemark.subLocality, placemark.locality, placemark.administrativeArea]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { partial, value in
                if !partial.contains(value) { partial.append(value) }
            }
            .joined(separator: " ")

        if district.isEmpty || title.contains(district) {
            return title
        }
        return "\(title) · \(district)"
    }
}

// MARK: - Map preview

struct ActivityCreateLocationMapPreview: View {
    let coordinate: CLLocationCoordinate2D?
    let pinTitle: String
    let showsPin: Bool

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            if showsPin, let coordinate {
                Marker(pinTitle, coordinate: coordinate)
            }
        }
        .frame(height: 180)
        .clipShape(
            RoundedRectangle(
                cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            if coordinate == nil {
                RoundedRectangle(
                    cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius,
                    style: .continuous
                )
                .fill(.ultraThinMaterial)
                .overlay {
                    Label(
                        String(
                            localized: "activity.create.location.map.hint",
                            defaultValue: "搜索或点选下方地点",
                            comment: "Location map empty hint"
                        ),
                        systemImage: "mappin.and.ellipse"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mapAccessibilityLabel)
        .onAppear {
            updateCamera(animated: false)
        }
        .onChange(of: cameraFocusKey) { _, _ in
            updateCamera(animated: true)
        }
    }

    private var cameraFocusKey: String {
        guard let coordinate else { return "none" }
        return "\(coordinate.latitude),\(coordinate.longitude),\(showsPin)"
    }

    private var mapAccessibilityLabel: String {
        if showsPin, let coordinate {
            return String(
                format: String(
                    localized: "activity.create.location.map.selected.a11y.format",
                    defaultValue: "地图预览：%@",
                    comment: "Map preview a11y; %@ is place name"
                ),
                locale: .current,
                pinTitle
            )
        }
        return String(
            localized: "activity.create.location.map.hint",
            defaultValue: "搜索或点选下方地点",
            comment: "Location map empty hint"
        )
    }

    private func updateCamera(animated: Bool) {
        guard let coordinate else {
            cameraPosition = .automatic
            return
        }
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: showsPin ? 900 : 4_000,
            longitudinalMeters: showsPin ? 900 : 4_000
        )
        if animated {
            withAnimation(.easeInOut(duration: 0.28)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }
}

// MARK: - Picker sheet

struct ActivityCreateLocationPickerSheet: View {
    @Binding var locationName: String
    @Environment(\.dismiss) private var dismiss

    @State private var searchModel = ActivityCreateLocationSearchModel()
    @State private var locationManager = ActivityCreateLocationBiasManager()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ActivityCreateLocationMapPreview(
                        coordinate: searchModel.mapFocusCoordinate,
                        pinTitle: searchModel.mapFocusTitle,
                        showsPin: searchModel.selectedResult != nil
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                if let searchErrorMessage = searchModel.searchErrorMessage {
                    Text(searchErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if searchModel.isSearching, searchModel.results.isEmpty {
                    HStack {
                        ProgressView()
                        Text(
                            String(
                                localized: "activity.create.location.searching",
                                defaultValue: "正在搜索地点…",
                                comment: "Searching locations"
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                } else if searchModel.results.isEmpty, searchModel.query.count >= 2 {
                    ContentUnavailableView(
                        String(
                            localized: "activity.create.location.empty.title",
                            defaultValue: "没找到相关地点",
                            comment: "Location search empty"
                        ),
                        systemImage: "mappin.slash",
                        description: Text(
                            String(
                                localized: "activity.create.location.empty.subtitle",
                                defaultValue: "试试商场、地铁站、咖啡馆或地标名称",
                                comment: "Location search empty hint"
                            )
                        )
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(searchModel.results) { result in
                        Button {
                            searchModel.selectResult(id: result.id)
                        } label: {
                            ActivityCreateLocationResultRow(
                                result: result,
                                isSelected: searchModel.selectedResultID == result.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(
                String(
                    localized: "activity.create.location.picker.title",
                    defaultValue: "选择集合地点",
                    comment: "Location picker title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: Binding(
                    get: { searchModel.query },
                    set: { searchModel.updateQuery($0) }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(
                    String(
                        localized: "activity.create.location.search.prompt",
                        defaultValue: "搜索商场、地铁站、咖啡馆、地标",
                        comment: "Location search prompt"
                    )
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        locationManager.requestBias(
                            for: searchModel,
                            source: .activityCreateLocationNearby
                        )
                    } label: {
                        Label(
                            String(
                                localized: "activity.create.location.nearby",
                                defaultValue: "附近",
                                comment: "Search near current location"
                            ),
                            systemImage: "location"
                        )
                    }
                    .accessibilityHint(
                        String(
                            localized: "activity.create.location.nearby.hint",
                            defaultValue: "按当前位置推荐周边地点",
                            comment: "Nearby location hint"
                        )
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                if searchModel.selectedResult != nil {
                    confirmBar
                }
            }
        }
        .onAppear {
            locationManager.requestBias(
                for: searchModel,
                source: .activityCreateLocationPicker
            )
        }
    }

    private var confirmBar: some View {
        Button {
            guard let confirmed = searchModel.confirmSelection() else { return }
            locationName = confirmed
            dismiss()
        } label: {
            Text(
                String(
                    localized: "activity.create.location.confirm",
                    defaultValue: "确认集合地点",
                    comment: "Confirm meetup location"
                )
            )
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .sparkMinimumTouchTarget()
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .background(.bar)
        .accessibilityHint(
            String(
                localized: "activity.create.location.confirm.hint",
                defaultValue: "将所选地点用于本次活动",
                comment: "Confirm location hint"
            )
        )
    }
}

// MARK: - Rows

struct ActivityCreateLocationResultRow: View {
    let result: ActivityCreateLocationResult
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                if !result.subtitle.isEmpty {
                    Text(result.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ActivityCreateLocationField: View {
    @Binding var locationName: String
    @State private var showsPicker = false

    var body: some View {
        Button {
            showsPicker = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                if trimmedLocation.isEmpty {
                    Text(
                        String(
                            localized: "activity.create.location.choose",
                            defaultValue: "选择集合地点",
                            comment: "Choose meetup location"
                        )
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayTitle)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        if let subtitle = displaySubtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locationAccessibilityLabel)
        .accessibilityHint(
            String(
                localized: "activity.create.location.choose.hint",
                defaultValue: "搜索并选择见面地点",
                comment: "Choose location hint"
            )
        )
        .sheet(isPresented: $showsPicker) {
            ActivityCreateLocationPickerSheet(locationName: $locationName)
        }
    }

    private var trimmedLocation: String {
        locationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayTitle: String {
        let parts = trimmedLocation.split(separator: " · ", maxSplits: 1, omittingEmptySubsequences: true)
        return parts.first.map(String.init) ?? trimmedLocation
    }

    private var displaySubtitle: String? {
        let parts = trimmedLocation.split(separator: " · ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2 else { return nil }
        return String(parts[1])
    }

    private var locationAccessibilityLabel: String {
        if trimmedLocation.isEmpty {
            return String(
                localized: "activity.create.location.choose",
                defaultValue: "选择集合地点",
                comment: "Choose meetup location"
            )
        }
        return trimmedLocation
    }
}

// MARK: - Location bias

@MainActor
@Observable
final class ActivityCreateLocationBiasManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private weak var searchModel: ActivityCreateLocationSearchModel?
    private var telemetrySource: SparkPermissionTelemetry.Source = .activityCreateLocationPicker
    private var didRequestPrompt = false

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestBias(for searchModel: ActivityCreateLocationSearchModel, source: SparkPermissionTelemetry.Source) {
        self.searchModel = searchModel
        telemetrySource = source
        let status = manager.authorizationStatus
        SparkPermissionTelemetry.statusChecked(
            permission: .locationWhenInUse,
            source: source,
            status: SparkPermissionTelemetry.locationStatus(from: status)
        )

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            didRequestPrompt = true
            SparkPermissionTelemetry.promptRequested(permission: .locationWhenInUse, source: source)
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            SparkPermissionTelemetry.promptResult(
                permission: .locationWhenInUse,
                source: source,
                outcome: SparkPermissionTelemetry.outcome(from: status)
            )
        @unknown default:
            break
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let regionCoordinate = coordinate
        Task { @MainActor [weak self] in
            self?.searchModel?.updateRegion(to: regionCoordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.didRequestPrompt, status != .notDetermined {
                SparkPermissionTelemetry.promptResult(
                    permission: .locationWhenInUse,
                    source: self.telemetrySource,
                    outcome: SparkPermissionTelemetry.outcome(from: status)
                )
                self.didRequestPrompt = false
            }
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            }
        }
    }
}

#Preview("Location field — empty") {
    @Previewable @State var location = ""
    Form {
        ActivityCreateLocationField(locationName: $location)
    }
}

#Preview("Location field — selected") {
    @Previewable @State var location = "星巴克(静安嘉里店) · 静安区"
    Form {
        ActivityCreateLocationField(locationName: $location)
    }
}
