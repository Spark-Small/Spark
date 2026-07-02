// Module: SparkMessages — Scan QR codes for activity / conversation deep links.

import AVFoundation
import PhotosUI
import SparkCore
import SparkDesignSystem
import SwiftUI
import VisionKit

struct MessagesQRScanSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onScannedPayload: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                    MessagesQRScannerRepresentable { payload in
                        onScannedPayload(payload)
                        dismiss()
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    ContentUnavailableView {
                        Label(
                            String(
                                localized: "messages.scan.unavailable.title",
                                defaultValue: "无法使用相机",
                                comment: "QR scan unavailable"
                            ),
                            systemImage: "camera.fill"
                        )
                    } description: {
                        Text(
                            String(
                                localized: "messages.scan.unavailable.subtitle",
                                defaultValue: "请检查相机权限，或稍后再试。",
                                comment: "QR scan unavailable hint"
                            )
                        )
                    }
                }
            }
            .onAppear {
                SparkPermissionTelemetry.trackCameraAccess(source: .messagesQRScan)
            }
            .navigationTitle(
                String(localized: "messages.scan.title", defaultValue: "扫一扫", comment: "QR scan title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct MessagesQRScannerRepresentable: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            SparkPermissionTelemetry.promptRequested(permission: .camera, source: .messagesQRScan)
        }
        guard !uiViewController.isScanning else { return }
        try? uiViewController.startScanning()
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCode: onCode)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onCode: (String) -> Void

        init(onCode: @escaping (String) -> Void) {
            self.onCode = onCode
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard let item = addedItems.first else { return }
            if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue {
                dataScanner.stopScanning()
                onCode(payload)
            }
        }
    }
}

#Preview {
    MessagesQRScanSheet(onScannedPayload: { _ in })
}
