//
//  PhotoVerificationEngine.swift
//  坐标系
//
//  本机照片核验：摄像头采集帧 ↔ 资料认证照（1–2 张）Vision 人脸比对。
//  不引入第三方商业 SDK；影像留在设备，不上传。
//

import CoreGraphics
import UIKit
import Vision
import CoordinateModels

enum PhotoVerificationEngine {
    struct Outcome: Sendable {
        var passed: Bool
        /// 0…1，越高越像（多基准时取最高分）
        var similarity: Double
        var reasons: [String]
    }

    /// 通过阈值：演示环境略宽松，正式版可上调。
    static let passThreshold: Double = 0.72

    /// 采集帧与多张认证照比对，取最高相似度。
    static func verify(references: [UIImage], capture: UIImage) async -> Outcome {
        // 认证照可能是相册原图：离开主线程再跑 Vision
        await Task.detached(priority: .userInitiated) {
            analyze(references: references, capture: capture)
        }.value
    }

    /// 兼容旧单图 API。
    static func verify(profile: UIImage, selfie: UIImage) async -> Outcome {
        await verify(references: [profile], capture: selfie)
    }

    // MARK: - Pipeline

    private static func analyze(references: [UIImage], capture: UIImage) -> Outcome {
        var reasons: [String] = []

        guard !references.isEmpty else {
            return Outcome(
                passed: false,
                similarity: 0,
                reasons: ["请先在个人资料上传 1–2 张认证照片。"]
            )
        }

        guard let captureFace = primaryFace(in: capture) else {
            return Outcome(
                passed: false,
                similarity: 0,
                reasons: ["未检测到人脸，请正对镜头、光线充足后重拍。"]
            )
        }

        if let quality = faceCaptureQuality(in: capture), quality < 0.35 {
            reasons.append("画面清晰度偏低，请补光后重拍。")
        }

        let coverage = faceCoverage(captureFace.boundingBox)
        if coverage < 0.08 {
            reasons.append("脸部占比过小，请靠近一些再拍。")
        } else if coverage > 0.85 {
            reasons.append("脸部裁切过近，请稍后退露出完整面部。")
        }

        guard let captureLandmarks = faceLandmarks(in: capture, observation: captureFace) else {
            reasons.append("未能提取面部特征，请换光线更充足的环境重拍。")
            return Outcome(passed: false, similarity: 0, reasons: reasons)
        }

        let captureVector = landmarkVector(captureLandmarks)
        guard captureVector.count >= 16 else {
            reasons.append("面部特征点不足，请正对镜头重拍。")
            return Outcome(passed: false, similarity: 0, reasons: reasons)
        }

        var bestSimilarity = 0.0
        var matchedAnyReference = false

        for reference in references {
            guard let refFace = primaryFace(in: reference),
                  let refLandmarks = faceLandmarks(in: reference, observation: refFace)
            else { continue }
            let refVector = landmarkVector(refLandmarks)
            guard refVector.count >= 16 else { continue }
            matchedAnyReference = true
            let score = cosineSimilarity(normalize(refVector), normalize(captureVector))
            bestSimilarity = max(bestSimilarity, score)
        }

        guard matchedAnyReference else {
            reasons.append("认证照中未检测到清晰正脸，请更换后再试。")
            return Outcome(passed: false, similarity: 0, reasons: reasons)
        }

        if bestSimilarity < passThreshold {
            reasons.append("与认证照相似度不足，请本人出镜并正对镜头。")
        }

        let passed = reasons.isEmpty && bestSimilarity >= passThreshold
        if passed {
            return Outcome(passed: true, similarity: bestSimilarity, reasons: [])
        }
        if reasons.isEmpty {
            reasons.append("核验未通过，请重试。")
        }
        return Outcome(passed: false, similarity: bestSimilarity, reasons: reasons)
    }

    // MARK: - Vision helpers

    private static func primaryFace(in image: UIImage) -> VNFaceObservation? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: cgOrientation(from: image),
            options: [:]
        )
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
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: cgOrientation(from: image),
            options: [:]
        )
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
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: cgOrientation(from: image),
            options: [:]
        )
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
