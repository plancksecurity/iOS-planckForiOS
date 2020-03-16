//
//  ClientCertificatePasswordViewModel.swift
//  pEp
//
//  Created by Adam Kowalski on 03/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol ClientCertificatePasswordViewModelPasswordChangeDelegate: class {
    func didEnter(password: String)
}

protocol ClientCertificatePasswordViewModelDelegate: class {
    func dismiss()
    func showError(type: importError, dissmisAfterError: Bool)
}

enum importError {
    case wrongPasswrd
    case corruptedFile
}

final class ClientCertificateImportViewModel {

    weak private var passwordChangeDelegate: ClientCertificatePasswordViewModelPasswordChangeDelegate?
    weak private var delegate: ClientCertificatePasswordViewModelDelegate?
    private let clientCertificateUtil: ClientCertificateUtilProtocol
    
    private var p12Data: Data?

    init(delegate: ClientCertificatePasswordViewModelDelegate? = nil,
         passwordChangeDelegate: ClientCertificatePasswordViewModelPasswordChangeDelegate? = nil,
         clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
        self.delegate = delegate
        self.passwordChangeDelegate = passwordChangeDelegate
        self.clientCertificateUtil = clientCertificateUtil ?? ClientCertificateUtil()
    }
    
    public func importClientCertificate(at url: URL) {
        do {
            p12Data = try Data(contentsOf: url)
        } catch {
            delegate?.showError(type: .corruptedFile, dissmisAfterError: true)
            return
        }
    }
    
    public func handlePassphraseEntered(pass: String) {
        guard let data = p12Data else {
            Log.shared.errorAndCrash("Invalid state: Password field should never been shown before having p12Data.")
            return
        }
        do {
            try clientCertificateUtil.storeCertificate(p12Data: data, password: pass)
            delegate?.dismiss()
        } catch ClientCertificateUtil.ImportError.wrongPassword {
            delegate?.showError(type: .wrongPasswrd, dissmisAfterError: false)
        } catch {
            delegate?.showError(type: .corruptedFile, dissmisAfterError: true)
        }
    }

    public func handleCancelButtonPresed() {
        delegate?.dismiss()
    }
}


//private func showCorruptedFileError(in vc: UIViewController) {
//    UIUtils.showAlertWithOnlyPositiveButton(title: Localized.CorruptedFileError.title,
//                                            message: Localized.CorruptedFileError.message) { [weak self] in
//                                                guard let me = self else {
//                                                    Log.shared.lostMySelf()
//                                                    return
//                                                }
//                                                me.dismiss(vc: vc)
//    }
//}


//private func showWrongPasswordError() {
//    guard let vc = clientCertificatePasswordVC else {
//        Log.shared.errorAndCrash("No VC")
//        return
//    }
//    UIUtils.showTwoButtonAlert(withTitle: Localized.WrongPasswordError.title,
//                               message: Localized.WrongPasswordError.message,
//                               cancelButtonText: Localized.no,
//                               positiveButtonText: Localized.yes,
//                               cancelButtonAction: { [weak self] in
//                                guard let me = self else {
//                                    Log.shared.lostMySelf()
//                                    return
//                                }
//                                me.dismiss(vc: vc)
//        }, positiveButtonAction: {
//            // We don't need to do something here. Our expectation is close this alert
//    })
//}
