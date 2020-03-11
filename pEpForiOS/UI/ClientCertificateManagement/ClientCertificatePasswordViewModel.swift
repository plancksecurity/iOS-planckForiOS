//
//  ClientCertificatePasswordViewModel.swift
//  pEp
//
//  Created by Adam Kowalski on 03/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ClientCertificatePasswordViewModelPasswordChangeDelegate: class {
    func didEnter(password: String)
}

protocol ClientCertificatePasswordViewModelDelegate: class {
    func dismiss()
}

final class ClientCertificatePasswordViewModel {

    weak private var passwordChangeDelegate: ClientCertificatePasswordViewModelPasswordChangeDelegate?
    weak private var delegate: ClientCertificatePasswordViewModelDelegate?

    init(delegate: ClientCertificatePasswordViewModelDelegate? = nil,
         passwordChangeDelegate: ClientCertificatePasswordViewModelPasswordChangeDelegate? = nil) {
        self.delegate = delegate
        self.passwordChangeDelegate = passwordChangeDelegate
    }

    public func handleOkButtonPressed(password: String) {
        passwordChangeDelegate?.didEnter(password: password)
    }

    public func handleCancelButtonPresed() {
        delegate?.dismiss()
    }
}
