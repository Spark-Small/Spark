//
//  PassportOCRService.swift
//  坐标系
//
//  护照资料页本机 Vision OCR；解析走 Domain UC。诚实披露为「本机识别」。
//

import CoordinateDomain
import CoordinateModels
import Foundation
import UIKit

enum PassportOCRError: LocalizedError {
    case unrecognizedText
    case parseFailed(ParsePassportIdentityError)
    case imageUnreadable
    case notPassportLike

    var errorDescription: String? {
        switch self {
        case .unrecognizedText:
            return "未能识别护照文字，请重新拍摄清晰资料页"
        case .parseFailed(.underage):
            return "未满 \(ProfileDemographicsLimits.ageMin) 周岁，无法完成实名"
        case .parseFailed(.missingSex):
            return "未识别到性别，请拍摄完整护照资料页"
        case .parseFailed(.missingDocumentNumber):
            return "未识别到护照号码，请确认拍摄的是资料页"
        case .parseFailed(.invalidBirthDate), .parseFailed(.unrecognized):
            return "护照信息无法解析，请拍摄含机读码或出生日期的资料页"
        case .imageUnreadable:
            return "图片无法读取，请重试"
        case .notPassportLike:
            return "未识别到护照特征，请拍摄护照资料页"
        }
    }
}

enum PassportOCRService {
    private static let parseUC = ParsePassportIdentityUseCase()

    static func verify(
        dataPageImage: UIImage,
        now: Date = .now
    ) async throws -> RealNameDemographicsResult {
        let text: String
        do {
            text = try await DocumentVisionTextRecognizer.recognizeText(in: dataPageImage)
        } catch ChineseIDCardOCRError.unrecognizedText {
            throw PassportOCRError.unrecognizedText
        } catch ChineseIDCardOCRError.imageUnreadable {
            throw PassportOCRError.imageUnreadable
        }

        guard ParsePassportIdentityUseCase.looksLikePassport(text) else {
            throw PassportOCRError.notPassportLike
        }

        do {
            return try parseUC.parse(fromOCRText: text, now: now)
        } catch let error as ParsePassportIdentityError {
            throw PassportOCRError.parseFailed(error)
        }
    }
}
