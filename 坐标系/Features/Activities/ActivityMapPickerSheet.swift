//
//  ActivityMapPickerSheet.swift
//  坐标系
//
//  地图选点：系统 `.searchable` + `MKLocalSearchCompleter` / `MKLocalSearch`。
//

import MapKit
import SwiftUI
import CoordinateModels

@MainActor
@Observable
private final class ActivityPlaceSearchModel: NSObject, MKLocalSearchCompleterDelegate {
    var query = "" {
        didSet {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            completer.queryFragment = trimmed
            if trimmed.isEmpty {
                completions = []
            }
        }
    }

    private(set) var completions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
    }

    func mapItem(for completion: MKLocalSearchCompletion) async -> MKMapItem? {
        let request = MKLocalSearch.Request(completion: completion)
        return try? await MKLocalSearch(request: request).start().mapItems.first
    }
}

struct ActivityMapPickerSheet: View {
    @Binding var locationText: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?

    @Environment(\.dismiss) private var dismiss
    @Environment(LocationService.self) private var location
    @State private var search = ActivityPlaceSearchModel()
    @State private var isSearchPresented = false
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var pin = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
    @State private var label = "地图选点"
    @State private var isResolvingSearch = false

    private var hasQuery: Bool {
        !search.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                mapCanvas

                if isSearchPresented, hasQuery {
                    searchResultsOverlay
                }
            }
            .navigationTitle("地图选点")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $search.query,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索地点或地址"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .platformSheetConfirmationToolbar(
                "使用此位置",
                isEnabled: !isResolvingSearch,
                emphasizesWhenEnabled: true,
                action: commitSelection
            )
            .safeAreaInset(edge: .bottom) {
                bottomChrome
            }
            .onAppear(perform: bootstrap)
            .onChange(of: position) { _, newPosition in
                if let region = newPosition.region {
                    search.updateRegion(region)
                }
            }
            .task(id: geocodeTaskID) {
                guard !isResolvingSearch else { return }
                let fallback = coordinateFallback(pin)
                label = await MapKitReverseGeocoding.addressLabel(for: pin) ?? fallback
            }
        }
        .platformSheet(.form)
    }

    // MARK: - Map

    private var mapCanvas: some View {
        MapReader { proxy in
            Map(position: $position) {
                Marker(label, coordinate: pin)
            }
            .mapStyle(.standard(elevation: .realistic))
            .onTapGesture { screenPoint in
                guard !isSearchPresented || !hasQuery else { return }
                if let coordinate = proxy.convert(screenPoint, from: .local) {
                    pin = coordinate
                    isSearchPresented = false
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var searchResultsOverlay: some View {
        List {
            if isResolvingSearch {
                ProgressView("正在定位…")
            }

            ForEach(Array(search.completions.enumerated()), id: \.offset) { _, completion in
                Button {
                    Task { await selectCompletion(completion) }
                } label: {
                    VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                        Text(completion.title)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        if !completion.subtitle.isEmpty {
                            Text(completion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if search.completions.isEmpty, !isResolvingSearch {
                ContentUnavailableView.search(text: search.query)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .platformOverlayMaterialFill()
    }

    private var bottomChrome: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text(bottomChromeHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PlatformMetrics.contentInset)
        .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
        .platformBarMaterialFill()
        .accessibilityElement(children: .combine)
    }

    private var bottomChromeHint: String {
        if isResolvingSearch {
            return "正在定位，完成后可使用此位置"
        }
        if hasQuery, isSearchPresented {
            return "从结果中选择，或关闭搜索后点按地图"
        }
        return "搜索地点，或点按地图放置标记"
    }

    // MARK: - Actions

    private var geocodeTaskID: String {
        String(format: "%.6f,%.6f", pin.latitude, pin.longitude)
    }

    private func bootstrap() {
        if let latitude, let longitude {
            pin = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            focus(on: pin, span: 0.04)
        } else if let user = location.coordinate {
            pin = user
            focus(on: user, span: 0.04)
        }
        if let region = position.region {
            search.updateRegion(region)
        }
        location.requestWhenInUse()
        location.refresh()
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) async {
        isResolvingSearch = true
        defer { isResolvingSearch = false }

        guard let item = await search.mapItem(for: completion) else { return }
        let coordinate = item.location.coordinate
        pin = coordinate
        label = placeLabel(for: item, completion: completion)
        focus(on: coordinate, span: 0.02)
        search.query = ""
        isSearchPresented = false
    }

    private func commitSelection() {
        latitude = pin.latitude
        longitude = pin.longitude
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        locationText = trimmed.isEmpty ? coordinateFallback(pin) : trimmed
        dismiss()
    }

    private func focus(on coordinate: CLLocationCoordinate2D, span: CLLocationDegrees) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
        position = .region(region)
        search.updateRegion(region)
    }

    private func placeLabel(for item: MKMapItem, completion: MKLocalSearchCompletion) -> String {
        if let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            let subtitle = completion.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !subtitle.isEmpty, !name.contains(subtitle) {
                return "\(name) · \(subtitle)"
            }
            return name
        }
        let title = completion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let subtitle = completion.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty, !subtitle.isEmpty {
            return "\(title) · \(subtitle)"
        }
        return title.isEmpty ? coordinateFallback(pin) : title
    }

    private func coordinateFallback(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
}
