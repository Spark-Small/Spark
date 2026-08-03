//
//  PhotoVerificationEngine.swift
//  坐标系
//
//  本机照片核验（Bumble 式形象认证）：Vision 人脸检测 + 质量 + 关键点比对。
//  不引入第三方商业 SDK；影像留在设备，不上传。
//

import CoreGraphics
import UIKit
import Vision

enum PhotoVerificationEngine {
    struct Outcome: Sendable {
        var passed: Bool
        /// 0…1，越高越像
        var similarity: Double
        var reasons: [String]
    }

    /// 通过阈值：演示环境略宽松，正式版可上调并接活体。
    static let passThreshold: Double = 0.72

    static func verify(profile: UIImage, selfie: UIImage) async -> Outcome {
        // Vision 推理很快；保持同线程避免 UIImage Sendable 约束。
        analyze(profile: profile, selfie: selfie)
    }

    // MARK: - Pipeline

    private static func analyze(profile: UIImage, selfie: UIImage) -> Outcome {
        var reasons: [String] = []

        guard let profileFace = primaryFace(in: profile) else {
            return Outcome(passed: false, similarity: 0, reasons: ["头像中未检测到清晰人脸，请更换正脸头像后再试。"])
        }
        guard let selfieFace = primaryFace(in: selfie) else {
            return Outcome(passed: false, similarity: 0, reasons: ["自拍中未检测到人脸，请正对镜头、光线充足后重拍。"])
        }

        if let quality = faceCaptureQuality(in: selfie), quality < 0.35 {
            reasons.append("自拍清晰度偏低，请补光后重拍。")
        }

        let selfieCoverage = faceCoverage(selfieFace.boundingBox)
        if selfieCoverage < 0.08 {
            reasons.append("脸部占比过小，请靠近一些再拍。")
        } else if selfieCoverage > 0.85 {
            reasons.append("脸部裁切过近，请稍后退露出完整面部。")
        }

        guard let profileLandmarks = faceLandmarks(in: profile, observation: profileFace),
              let selfieLandmarks = faceLandmarks(in: selfie, observation: selfieFace)
        else {
            reasons.append("未能提取面部特征，请换一张更清晰的正脸照片。")
            return Outcome(passed: false, similarity: 0, reasons: reasons)
        }

        let profileVector = landmarkVector(profileLandmarks)
        let selfieVector = landmarkVector(selfieLandmarks)
        guard profileVector.count >= 16, selfieVector.count >= 16 else {
            reasons.append("面部特征点不足，请正对镜头重拍。")
            return Outcome(passed: false, similarity: 0, reasons: reasons)
        }

        let similarity = cosineSimilarity(
            normalize(profileVector),
            normalize(selfieVector)
        )

        if similarity < passThreshold {
            reasons.append("自拍与头像相似度不足，请使用本人近期正脸照片。")
        }

        let passed = reasons.isEmpty && similarity >= passThreshold
        if passed {
            return Outcome(passed: true, similarity: similarity, reasons: [])
        }
        if reasons.isEmpty {
            reasons.append("核验未通过，请重试。")
        }
        return Outcome(passed: false, similarity: similarity, reasons: reasons)
    }

    // MARK: - Vision helpers

    private static func primaryFace(in image: UIImage) -> VNFaceObservation? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation(from: image), options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        let faces = request.results ?? []
        guard faces.count == 1 else { return nil }
        return faces.first
    }

    private static func faceLandmarks(
        in image: UIImage,
        observation: VNFaceObservation
    ) -> VNFaceLandmarks2D? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectFaceLandmarksRequest()
        request.inputFaceObservations = [observation]
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation(from: image), options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        return request.results?.first?.landmarks
    }

    private static func faceCaptureQuality(in image: UIImage) -> Float? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectFaceCaptureQualityRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation(from: image), options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        return request.results?.first?.faceCaptureQuality
    }

    private static func faceCoverage(_ box: CGRect) -> CGFloat {
        max(0, box.width * box.height)
    }

    private static func landmarkVector(_ landmarks: VNFaceLandmarks2D) -> [Double] {
        var points: [CGPoint] = []
        let regions: [VNFaceLandmarkRegion2D?] = [
            landmarks.faceContour,
            landmarks.leftEye,
            landmarks.rightEye,
            landmarks.nose,
            landmarks.outerLips,
            landmarks.leftEyebrow,
            landmarks.rightEyebrow
        ]
        for region in regions {
            guard let region else { continue }
            points.append(contentsOf: region.normalizedPoints)
        }
        guard let first = points.first else { return [] }
        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for p in points {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
        }
        let w = max(maxX - minX, 0.001)
        let h = max(maxY - minY, 0.001)
        var vector: [Double] = []
        vector.reserveCapacity(points.count * 2)
        for p in points {
            vector.append(Double((p.x - minX) / w))
            vector.append(Double((p.y - minY) / h))
        }
        return vector
    }

    private static func normalize(_ vector: [Double]) -> [Double] {
        let mean = vector.reduce(0, +) / Double(max(vector.count, 1))
        let centered = vector.map { $0 - mean }
        let norm = sqrt(centered.reduce(0) { $0 + $1 * $1 })
        guard norm > 1e-9 else { return centered }
        return centered.map { $0 / norm }
    }

    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let n = min(a.count, b.count)
        guard n > 0 else { return 0 }
        var dot = 0.0
        for i in 0..<n {
            dot += a[i] * b[i]
        }
        // 归一化向量点积 ∈ [-1, 1] → 映射到 0…1
        return min(1, max(0, (dot + 1) / 2))
    }

    private static func cgOrientation(from image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
