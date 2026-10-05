//
//  PhotoVerificationCamera.swift
//  坐标系
//
//  前置摄像头采集（形象认证；认证路径禁用相册）+ 相机权限门闸。
//  UIImagePicker 须由宿主 VC present，勿直接作为 fullScreenCover 根（会黑屏/无反应）。
//

import AVFoundation
import SwiftUI
import UIKit

// MARK: - Access

enum PhotoVerificationCameraCopy {
    static let permissionTitle = "需要相机权限"
    static let permissionMessage = "防欺诈认证须现场自拍。请在系统设置中允许坐标系使用相机。"
    static let unavailableTitle = "无法使用相机"
    static let unavailableMessage = "当前设备没有可用摄像头，无法完成现场采集（模拟器通常不支持）。"
    static let restrictedMessage = "相机使用权受限，无法进行防欺诈认证采集。"
    static let photosMissingTitle = "还不能采集"
    static let photosMissingMessage = "请先点「添加认证照」上传 1–2 张本人正脸照，再打开摄像头采集。"
    static let openSettings = "去设置"
    static let dismiss = "好的"
}

@MainActor
enum PhotoVerificationCameraAccess {
    enum Status: Equatable {
        case ready
        case unavailable
        case denied
        case restricted
    }

    static var isHardwareAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// 先确保硬件可用，再请求 / 读取视频（相机）授权。
    static func prepare() async -> Status {
        guard isHardwareAvailable else { return .unavailable }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .ready
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .ready : .denied
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Picker host

/// fullScreenCover 根：黑底宿主，在 `viewDidAppear` 里再 present `UIImagePickerController`。
struct PhotoVerificationCameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> PhotoVerificationCameraHostController {
        let host = PhotoVerificationCameraHostController()
        host.onImage = onImage
        host.onCancel = onCancel
        return host
    }

    func updateUIViewController(
        _ uiViewController: PhotoVerificationCameraHostController,
        context: Context
    ) {
        uiViewController.onImage = onImage
        uiViewController.onCancel = onCancel
    }
}

@MainActor
final class PhotoVerificationCameraHostController: UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    var onImage: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private var didPresentPicker = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPresentPicker else { return }
        didPresentPicker = true
        presentCameraPicker()
    }

    private func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            onCancel?()
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        if UIImagePickerController.isCameraDeviceAvailable(.front) {
            picker.cameraDevice = .front
        }
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            if let image {
                self?.onImage?(image)
            } else {
                self?.onCancel?()
            }
        }
    }
}
