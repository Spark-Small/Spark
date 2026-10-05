//
//  ChineseIDCardOCRService.swift
//  坐标系
//
//  身份证正反面本机 Vision OCR；解析号码走 Domain UC。诚实披露为「本机识别」。
//

import CoordinateDomain
import CoordinateModels
import Foundation
import UIKit

enum ChineseIDCardOCRError: LocalizedError {
    case unrecognizedText
    case frontParseFailed(ParseChineseResidentIDError)
    case backLooksEmpty
    case imageUnreadable

    var errorDescription: String? {
        switch self {
        case .unrecognizedText:
            return "未能识别证件文字，请重新拍摄清晰正面"
        case .frontParseFailed(.underage):
            return "未满 \(ProfileDemographicsLimits.ageMin) 周岁，无法完成实名"
        case .frontParseFailed(.checksumFailed), .frontParseFailed(.invalidFormat),
             .frontParseFailed(.invalidBirthDate):
            return "身份证号无法校验，请确认拍摄的是本人证件正面"
        case .backLooksEmpty:
            return "未识别到国徽面关键信息，请拍摄证件反面"
        case .imageUnreadable:
            return "图片无法读取，请重试"
        }
    }
}

enum ChineseIDCardOCRService {
    private static let parseUC = ParseChineseResidentIDUseCase()

    /// 正面：提取身份证号 → 性别/出生日期；反面：须识别到签发相关文案。
    static func verify(
        frontImage: UIImage,
        backImage: UIImage,
        now: Date = .now
    ) async throws -> RealNameDemographicsResult {
        let frontText = try await DocumentVisionTextRecognizer.recognizeText(in: frontImage)
        let backText = try await DocumentVisionTextRecognizer.recognizeText(in: backImage)

        guard looksLikeIDBack(backText) else {
            throw ChineseIDCardOCRError.backLooksEmpty
        }

        do {
            return try parseUC.parse(fromOCRText: frontText, now: now)
        } catch let error as ParseChineseResidentIDError {
            throw ChineseIDCardOCRError.frontParseFailed(error)
        }
    }

    private static func looksLikeIDBack(_ text: String) -> Bool {
        let normalized = text.replacingOccurrences(of: " ", with: "")
        let needles = ["签发机关", "有效期限", "中华人民共和国", "居民身份证"]
        return needles.contains(where: { normalized.contains($0) })
            || normalized.count >= 12
    }
}
