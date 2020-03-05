//
//  ClientCertificateManagementViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - Row

extension ClientCertificateManagementViewModel {
    struct Row {
        public var name: String {
            return clientCertificate.label ?? "--"
        }
        public var date: Date? {
            return clientCertificate.date
        }
        fileprivate let clientCertificate: ClientCertificate
    }
}

final class ClientCertificateManagementViewModel {
    private let clientCertificateUtil: ClientCertificateUtil
    private let verifiableAccount: VerifiableAccount
    public private(set) var rows = [Row]()

    public init(verifiableAccount: VerifiableAccount? = nil,
                clientCertificateUtil: ClientCertificateUtil = ClientCertificateUtil()) {
        self.clientCertificateUtil = clientCertificateUtil
        self.verifiableAccount = verifiableAccount ?? VerifiableAccount()
        setup()
    }

    public func handleDidSelect(rowAt indexPath: IndexPath) {
        verifiableAccount.clientCertificate = rows[indexPath.row].clientCertificate
    }

    public func loginViewModel() -> LoginViewModel {
        return LoginViewModel(verifiableAccount: verifiableAccount)
    }
}

// MARK: - Private

extension ClientCertificateManagementViewModel {
    private func setup() {
        rows = clientCertificateUtil.listCertificates().map { Row(clientCertificate: $0) }
    }
}
