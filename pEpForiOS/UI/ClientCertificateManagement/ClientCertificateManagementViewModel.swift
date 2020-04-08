//
//  ClientCertificateManagementViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

enum ClientCertificateAction {
    case newAccount
    case updateCertificate
}

protocol ClientCertificateManagementViewModelDelegate: class{
    func showInUseError(by: String)
}

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
    private let clientCertificateUtil: ClientCertificateUtilProtocol
    private var verifiableAccount: VerifiableAccountProtocol
    public weak var delegate: ClientCertificateManagementViewModelDelegate?
    public private(set) var rows = [Row]()
    public var accountToUpdate: Account?

    public init(verifiableAccount: VerifiableAccountProtocol? = nil,
                clientCertificateUtil: ClientCertificateUtilProtocol = ClientCertificateUtil(),
                account: Account? = nil) {
        self.clientCertificateUtil = clientCertificateUtil
        self.verifiableAccount = verifiableAccount ??
            VerifiableAccount.verifiableAccount(for: .clientCertificate)
        setup()
        accountToUpdate = account
    }
    
    public func backButtonText() -> String {
        if accountToUpdate != nil {
            return NSLocalizedString("Cancel",
                              comment: "Back button for client cert managment when shown from account")
        } else {
            return NSLocalizedString("Back",
                              comment: "Back button for client cert managment when shown from login")
        }
    }

    public func handleDidSelect(rowAt indexPath: IndexPath) -> ClientCertificateAction {
        let certificate = rows[indexPath.row].clientCertificate
        if let account = accountToUpdate {
            account.imapServer?.credentials.clientCertificate = certificate
            account.smtpServer?.credentials.clientCertificate = certificate
            Session.main.commit()
            return .updateCertificate
        } else {
            verifiableAccount.clientCertificate = rows[indexPath.row].clientCertificate
            return .newAccount
        }
    }

    public func loginViewModel() -> LoginViewModel {
        return LoginViewModel(verifiableAccount: verifiableAccount)
    }
    public func deleteCertificate(indexPath: IndexPath) -> Bool{
        let list = clientCertificateUtil.listCertificates(session: nil)
        do {
            try clientCertificateUtil.delete(clientCertificate: list[indexPath.row])
            rows.remove(at: indexPath.row)
            return true
        } catch {
            let cert = list[indexPath.row]
            delegate?.showInUseError(by: cert.label ?? "--")
            return false
        }
    }
    
    /// generate new rows from actual data
    public func handleNewCertificateImported() {
        setup()
    }
}

// MARK: - Private

extension ClientCertificateManagementViewModel {
    private func setup() {
        rows = clientCertificateUtil.listCertificates(session: nil).map { Row(clientCertificate: $0) }
    }
}
