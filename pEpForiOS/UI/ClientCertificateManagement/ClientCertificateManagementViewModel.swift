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
    private let clientCertificateUtil: ClientCertificateUtil
    private var verifiableAccount: VerifiableAccountProtocol
    public weak var delegate: ClientCertificateManagementViewModelDelegate?
    public private(set) var rows = [Row]()
    public var accountToUpdate: Account?

    /// If the view shows a navigation bar (it was presented by pushing it), we need to hide the cancel button as we have one already.
    /// Else, if it's not there (it was presented modally), we need to show it.
    /// As there is not a pure way to distinguish them, we handle that with this property.
    ///
    /// True to hide the cancel button. False to show it.
    public private(set) var shouldHideCancelButton: Bool

    public init(verifiableAccount: VerifiableAccountProtocol? = nil,
                clientCertificateUtil: ClientCertificateUtil = ClientCertificateUtil(),
                account: Account? = nil,
                shouldHideCancelButton: Bool = false) {
        self.clientCertificateUtil = clientCertificateUtil
        self.verifiableAccount = verifiableAccount ??
            VerifiableAccount.verifiableAccount(for: .clientCertificate)
        self.shouldHideCancelButton = shouldHideCancelButton
        setup()
        accountToUpdate = account
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
        let list = clientCertificateUtil.listCertificates()
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
        rows = clientCertificateUtil.listCertificates().map { Row(clientCertificate: $0) }
    }
}
