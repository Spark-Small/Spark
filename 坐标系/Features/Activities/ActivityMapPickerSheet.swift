//
//  ActivityMapPickerSheet.swift
//  坐标系
//

import MapKit
import SwiftUI
import CoordinateModels

struct ActivityMapPickerSheet: View {
    @Binding var locationText: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?

    @Environment(\.dismiss) private var dismiss
    @Environment(LocationService.self) private var location
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var pin = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
    @State private var label = "地图选点"

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $position) {
                    Marker(label, coordinate: pin)
                }
                .onTapGesture { screenPoint in
                    if let coordinate = proxy.convert(screenPoint, from: .local) {
                        pin = coordinate
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("地图选点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("使用此位置") {
                        latitude = pin.latitude
                        longitude = pin.longitude
                        if !label.isEmpty {
                            locationText = label
                        } else {
                            locationText = coordinateFallback(pin)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("点按地图放置标记")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, PlatformMetrics.contentInset)
                    .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
                    .platformBarMaterialFill()
            }
            .onAppear {
                if let latitude, let longitude {
                    pin = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    position = .region(
                        MKCoordinateRegion(
                            center: pin,
                            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                        )
                    )
                } else if let user = location.coordinate {
                    pin = user
                    position = .region(
                        MKCoordinateRegion(
                            center: user,
                            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                        )
                    )
                }
                location.requestWhenInUse()
                location.refresh()
            }
            // 官方写法：SwiftUI `.task` + MapKit `MKReverseGeocodingRequest`
            .task(id: geocodeTaskID) {
                let fallback = coordinateFallback(pin)
                label = await MapKitReverseGeocoding.addressLabel(for: pin) ?? fallback
            }
        }
        .platformSheet(.form)
    }

    private var geocodeTaskID: String {
        String(format: "%.6f,%.6f", pin.latitude, pin.longitude)
    }

    private func coordinateFallback(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
}
