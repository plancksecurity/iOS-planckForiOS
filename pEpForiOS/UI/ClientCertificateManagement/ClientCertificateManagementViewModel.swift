//
//  ClientCertificateManagementViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - Row

protocol ClientCertificateManagementViewModelDelegate: class{
    func showInUseError(by: String)
}

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
    public weak var delegate: ClientCertificateManagementViewModelDelegate?
    public private(set) var rows = [Row]()

    public init(verifiableAccount: VerifiableAccountProtocol? = nil,
                clientCertificateUtil: ClientCertificateUtil = ClientCertificateUtil()) {
        self.clientCertificateUtil = clientCertificateUtil
        self.verifiableAccount = verifiableAccount ??
            VerifiableAccount.verifiableAccount(for: .clientCertificate)
        setup()
    }

    public func handleDidSelect(rowAt indexPath: IndexPath) {
        verifiableAccount.clientCertificate = rows[indexPath.row].clientCertificate
    }

    public func loginViewModel() -> LoginViewModel {
        return LoginViewModel(verifiableAccount: verifiableAccount)
    }
    public func deleteCertificate(indexPath: IndexPath) -> Bool{
        let list = clientCertificateUtil.listCertificates()
        do {
            try clientCertificateUtil.delete(clientCertificate: list[indexPath.row])
            return true
        } catch {
            let cert = list[indexPath.row]
            delegate?.showInUseError(by: cert.label ?? "--")
            return false
        }
    }
}

// MARK: - Private

extension ClientCertificateManagementViewModel {
    private func setup() {
        rows = clientCertificateUtil.listCertificates().map { Row(clientCertificate: $0) }
    }
}
