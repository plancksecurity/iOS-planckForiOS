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
    func showError(type: importCertificateError, dissmisAfterError: Bool)
}

public enum importCertificateError {
    case wrongPassword
    case corruptedFile
}

final class ClientCertificateImportViewModel {

    weak private var passwordChangeDelegate: ClientCertificatePasswordViewModelPasswordChangeDelegate?
    weak private var delegate: ClientCertificatePasswordViewModelDelegate?
    private let clientCertificateUtil: ClientCertificateUtilProtocol
    private var certificateUrl: URL
    private var p12Data: Data?

    init(certificateUrl: URL, delegate: ClientCertificatePasswordViewModelDelegate? = nil,
         passwordChangeDelegate: ClientCertificatePasswordViewModelPasswordChangeDelegate? = nil,
         clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
        self.certificateUrl = certificateUrl
        self.delegate = delegate
        self.passwordChangeDelegate = passwordChangeDelegate
        self.clientCertificateUtil = clientCertificateUtil ?? ClientCertificateUtil()
    }
    
    public func importClientCertificate() {
        do {
            p12Data = try Data(contentsOf: certificateUrl)
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
            delegate?.showError(type: .wrongPassword, dissmisAfterError: false)
        } catch {
            delegate?.showError(type: .corruptedFile, dissmisAfterError: true)
        }
    }

    public func handleCancelButtonPresed() {
        delegate?.dismiss()
    }
}






