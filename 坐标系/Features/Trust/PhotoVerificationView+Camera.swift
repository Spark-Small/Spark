//
//  PhotoVerificationView+Camera.swift
//  坐标系
//
//  形象认证：打开摄像头前的权限 / 认证照门闸。
//

import SwiftUI

extension PhotoVerificationView {
    /// 先备齐认证照 → 申请相机权限 → 宿主 VC present 相机（不回落相册）。
    @MainActor
    func presentCameraIfAllowed() async {
        guard photosReady else {
            presentCameraAccessAlert(
                title: PhotoVerificationCameraCopy.photosMissingTitle,
                message: PhotoVerificationCameraCopy.photosMissingMessage,
                offersSettings: false
            )
            return
        }

        let status = await PhotoVerificationCameraAccess.prepare()
        switch status {
        case .ready:
            showCamera = true
        case .unavailable:
            presentCameraAccessAlert(
                title: PhotoVerificationCameraCopy.unavailableTitle,
                message: PhotoVerificationCameraCopy.unavailableMessage,
                offersSettings: false
            )
        case .denied:
            presentCameraAccessAlert(
                title: PhotoVerificationCameraCopy.permissionTitle,
                message: PhotoVerificationCameraCopy.permissionMessage,
                offersSettings: true
            )
        case .restricted:
            presentCameraAccessAlert(
                title: PhotoVerificationCameraCopy.unavailableTitle,
                message: PhotoVerificationCameraCopy.restrictedMessage,
                offersSettings: false
            )
        }
    }

    @MainActor
    func presentCameraAccessAlert(title: String, message: String, offersSettings: Bool) {
        cameraAccessTitle = title
        cameraAccessMessage = message
        cameraAccessOffersSettings = offersSettings
        showCameraAccessAlert = true
    }
}
