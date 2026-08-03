//
//  PassKitLoader.swift
//  坐标系
//
//  从签名落盘加载 PKPass，供系统 AddPassToWalletButton。
//

import Foundation
import PassKit

enum PassKitLoader {
    static func canAddPasses() -> Bool {
        PKAddPassesViewController.canAddPasses()
    }

    static func loadPKPass(for pass: PassRecord) -> PKPass? {
        let signedURL = PassDistribution.signedPassURL(for: pass)
        if let data = try? Data(contentsOf: signedURL),
           let pk = try? PKPass(data: data) {
            return pk
        }
        return nil
    }

    static func isInSystemWallet(_ pass: PassRecord) -> Bool {
        guard let pk = loadPKPass(for: pass) else { return pass.addedToSystemWallet }
        return PKPassLibrary().containsPass(pk)
    }
}
