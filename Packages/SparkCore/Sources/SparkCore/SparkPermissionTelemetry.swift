// Module: SparkCore — System permission funnel signposts (no PII).

import AVFoundation
import CoreLocation
import EventKit
import OSLog
import Photos
import UserNotifications

/// Structured analytics for permission prompts and outcomes. Payloads are enum strings only.
public enum SparkPermissionTelemetry {
    private static let logger = SparkLog.logger(category: "PermissionAnalytics")

    public enum Permission: String, Sendable {
        case locationWhenInUse = "location_when_in_use"
        case photoLibrary = "photo_library"
        case camera = "camera"
        case calendar = "calendar"
        case notifications = "notifications"
    }

    public enum Source: String, Sendable {
        case activityCreateLocationNearby = "activity_create_location_nearby"
        case activityCreateLocationPicker = "activity_create_location_picker"
        case activityCreateCover = "activity_create_cover"
        case communityCreatePost = "community_create_post"
        case messagesComposerPhoto = "messages_composer_photo"
        case messagesQRScan = "messages_qr_scan"
        case activityAddToCalendar = "activity_add_to_calendar"
        case activityRemindersToggle = "activity_reminders_toggle"
        case pushPermissionGuide = "push_permission_guide"
    }

    public enum Status: String, Sendable {
        case notDetermined = "not_determined"
        case authorized = "authorized"
        case authorizedWhenInUse = "authorized_when_in_use"
        case authorizedAlways = "authorized_always"
        case limited = "limited"
        case denied = "denied"
        case restricted = "restricted"
        case writeOnly = "write_only"
    }

    public enum Outcome: String, Sendable {
        case granted = "granted"
        case denied = "denied"
        case restricted = "restricted"
        case skipped = "skipped"
    }

    /// Current authorization before any prompt (e.g. picker opened, nearby tapped).
    public static func statusChecked(permission: Permission, source: Source, status: Status) {
        logger.info(
            "permission_status_checked permission=\(permission.rawValue, privacy: .public) source=\(source.rawValue, privacy: .public) status=\(status.rawValue, privacy: .public)"
        )
    }

    /// App requested the system permission dialog.
    public static func promptRequested(permission: Permission, source: Source) {
        logger.info(
            "permission_prompt_requested permission=\(permission.rawValue, privacy: .public) source=\(source.rawValue, privacy: .public)"
        )
    }

    /// User responded to the system dialog (or status changed after prompt).
    public static func promptResult(permission: Permission, source: Source, outcome: Outcome) {
        logger.info(
            "permission_prompt_result permission=\(permission.rawValue, privacy: .public) source=\(source.rawValue, privacy: .public) outcome=\(outcome.rawValue, privacy: .public)"
        )
    }

    /// User dismissed an in-app pre-prompt without requesting system authorization.
    public static func promptSkipped(permission: Permission, source: Source) {
        logger.info(
            "permission_prompt_skipped permission=\(permission.rawValue, privacy: .public) source=\(source.rawValue, privacy: .public)"
        )
    }

    // MARK: - Photo library

    public static func trackPhotoLibraryAccess(source: Source) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        statusChecked(permission: .photoLibrary, source: source, status: photoLibraryStatus(from: status))
    }

    public static func photoLibraryStatus(from status: PHAuthorizationStatus) -> Status {
        switch status {
        case .notDetermined:
            .notDetermined
        case .restricted:
            .restricted
        case .denied:
            .denied
        case .authorized:
            .authorized
        case .limited:
            .limited
        @unknown default:
            .denied
        }
    }

    // MARK: - Camera

    public static func trackCameraAccess(source: Source) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        statusChecked(permission: .camera, source: source, status: cameraStatus(from: status))
    }

    public static func cameraStatus(from status: AVAuthorizationStatus) -> Status {
        switch status {
        case .notDetermined:
            .notDetermined
        case .restricted:
            .restricted
        case .denied:
            .denied
        case .authorized:
            .authorized
        @unknown default:
            .denied
        }
    }

    // MARK: - Calendar

    public static func calendarStatus(from status: EKAuthorizationStatus) -> Status {
        switch status {
        case .notDetermined:
            .notDetermined
        case .restricted:
            .restricted
        case .denied:
            .denied
        case .fullAccess:
            .authorized
        case .writeOnly:
            .writeOnly
        @unknown default:
            .denied
        }
    }

    public static func calendarOutcome(granted: Bool, status: EKAuthorizationStatus) -> Outcome {
        if granted {
            return .granted
        }
        return status == .restricted ? .restricted : .denied
    }

    // MARK: - Notifications

    public static func notificationStatus(from status: UNAuthorizationStatus) -> Status {
        switch status {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .authorized:
            .authorized
        case .provisional:
            .authorized
        case .ephemeral:
            .authorized
        @unknown default:
            .denied
        }
    }

    public static func notificationOutcome(granted: Bool) -> Outcome {
        granted ? .granted : .denied
    }

    // MARK: - Location

    public static func locationStatus(from authorizationStatus: CLAuthorizationStatus) -> Status {
        switch authorizationStatus {
        case .notDetermined:
            .notDetermined
        case .authorizedWhenInUse:
            .authorizedWhenInUse
        case .authorizedAlways:
            .authorizedAlways
        case .denied:
            .denied
        case .restricted:
            .restricted
        @unknown default:
            .denied
        }
    }

    public static func outcome(from authorizationStatus: CLAuthorizationStatus) -> Outcome {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            .granted
        case .restricted:
            .restricted
        case .notDetermined, .denied:
            .denied
        @unknown default:
            .denied
        }
    }
}
