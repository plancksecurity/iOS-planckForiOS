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
            return clientCertificate.label
                ?? "--"
        }
        public var date: String {
            guard let date = clientCertificate.date else {
                return ""
            }
            return date.fullString()
        }
        fileprivate let clientCertificate: ClientCertificate
    }
}

final class ClientCertificateManagementViewModel {
    private let clientCertificateUtil: ClientCertificateUtil
    private var verifiableAccount: VerifiableAccountProtocol
    public private(set) var rows = [Row]()

    public init(verifiableAccount: VerifiableAccountProtocol? = nil,
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
    public func deleteCertificate(indexPath: IndexPath) {
        let list = clientCertificateUtil.listCertificates()
        do {
            try clientCertificateUtil.delete(clientCertificate: list[indexPath.row])
        } catch {
            Log.shared.errorAndCrash(message: "something goes wrong removing cert")
        }
        
    }
}

// MARK: - Private

extension ClientCertificateManagementViewModel {
    private func setup() {
        rows = clientCertificateUtil.listCertificates().map { Row(clientCertificate: $0) }
    }
}
