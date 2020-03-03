//
//  ClientCertificatePasswordViewModel.swift
//  pEp
//
//  Created by Adam Kowalski on 03/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ClientCertificatePasswordDelegate {
    func importCertificate(password: String)
    func dismiss()
}

final class ClientCertificatePasswordViewModel {

    let delegate: ClientCertificatePasswordDelegate

    init(delegate clientCertificateDelegate: ClientCertificatePasswordDelegate) {
        delegate = clientCertificateDelegate
    }

    public func importCertificateAction(password: String) {
        delegate.importCertificate(password: password)
    }

    public func dismissImportCertificateAction() {
        delegate.dismiss()
    }
}
