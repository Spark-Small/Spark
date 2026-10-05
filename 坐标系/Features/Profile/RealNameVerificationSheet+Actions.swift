//
//  RealNameVerificationSheet+Actions.swift
//  坐标系
//

import CoordinateModels
import PhotosUI
import SwiftUI
import UIKit

extension RealNameVerificationSheet {
    func restorePersistedMedia() {
        if let kind = user.realNameDocumentKind {
            documentKind = kind
        }
        frontLocalName = user.idCardFrontLocalName
        backLocalName = user.idCardBackLocalName
        passportLocalName = user.passportDataPageLocalName
        if let name = frontLocalName {
            frontImage = loadImage(named: name)
        }
        if let name = backLocalName {
            backImage = loadImage(named: name)
        }
        if let name = passportLocalName {
            passportImage = loadImage(named: name)
        }
    }

    @MainActor
    func loadFront(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            let (image, name) = try await persistPickerImage(item)
            if let old = frontLocalName, old != user.idCardFrontLocalName {
                LocalMediaLibrary.delete(named: old)
            }
            frontImage = image
            frontLocalName = name
            previewResult = nil
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadBack(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            let (image, name) = try await persistPickerImage(item)
            if let old = backLocalName, old != user.idCardBackLocalName {
                LocalMediaLibrary.delete(named: old)
            }
            backImage = image
            backLocalName = name
            previewResult = nil
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadPassport(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            let (image, name) = try await persistPickerImage(item)
            if let old = passportLocalName, old != user.passportDataPageLocalName {
                LocalMediaLibrary.delete(named: old)
            }
            passportImage = image
            passportLocalName = name
            previewResult = nil
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    @MainActor
    func recognizeAndApply() async {
        isRecognizing = true
        defer { isRecognizing = false }
        do {
            let result: RealNameDemographicsResult
            switch documentKind {
            case .chineseResidentID:
                guard let frontImage, let backImage else { return }
                result = try await ChineseIDCardOCRService.verify(
                    frontImage: frontImage,
                    backImage: backImage
                )
            case .passport:
                guard let passportImage else { return }
                result = try await PassportOCRService.verify(dataPageImage: passportImage)
            }
            previewResult = result
            var next = user
            next.applyRealName(result)
            switch result.documentKind {
            case .chineseResidentID:
                next.idCardFrontLocalName = frontLocalName
                next.idCardBackLocalName = backLocalName
            case .passport:
                next.passportDataPageLocalName = passportLocalName
            }
            user = next
            trust.bumpRevision()
            alertMessage = RealNameVerificationCopy.successFeedback
            dismiss()
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        }
    }

    func persistPickerImage(_ item: PhotosPickerItem) async throws -> (UIImage, String) {
        guard let data = try await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else {
            throw ChineseIDCardOCRError.imageUnreadable
        }
        guard let name = LocalMediaLibrary.saveJPEG(image) else {
            throw ChineseIDCardOCRError.imageUnreadable
        }
        return (image, name)
    }

    func loadImage(named name: String) -> UIImage? {
        guard let url = LocalMediaLibrary.fileURL(named: name),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }
}
