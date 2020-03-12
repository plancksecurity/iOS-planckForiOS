//
//  AccountTypeSelectorViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel



protocol AccountTypeSelectorViewModelDelegate: class {
    func showMustImportClientCertificateAlert()
    func showClientCertificateSeletionView()
}

class AccountTypeSelectorViewModel {
    private let clientCertificateUtil: ClientCertificateUtilProtocol

    private var verifiableAccount: VerifiableAccountProtocol?

    public weak var delegate: AccountTypeSelectorViewModelDelegate?

    /// list of providers to show
    private let accountTypes: [VerifiableAccount.AccountType] = [.gmail, .clientCertificate, .other]

    var chosenAccountType: VerifiableAccount.AccountType = .other

    init(clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
        self.clientCertificateUtil = clientCertificateUtil ?? ClientCertificateUtil()
    }

    var count: Int {
        get {
            return accountTypes.count
        }
    }

    subscript(index: Int) -> VerifiableAccount.AccountType {
        return accountTypes[index]
    }

    public func accountType(row: Int) -> VerifiableAccount.AccountType? {
        guard row < accountTypes.count else {
            Log.shared.errorAndCrash("Index out of range")
            return nil
        }
        return accountTypes[row]
    }

    public func handleDidChooseClientCertificate() {
        if clientCertificateUtil.listCertificates(session: nil).count == 0 {
            delegate?.showMustImportClientCertificateAlert()
        } else {
            chosenAccountType = .clientCertificate
            delegate?.showClientCertificateSeletionView()
        }
    }

    /// returns the text corresponding to the provider
    /// - Parameter provider: provider to obtain it's text
    public func fileNameOrText(provider: VerifiableAccount.AccountType) -> String {
        switch provider {
        case .gmail:
            return "asset-Google"
        case .other:
            return NSLocalizedString("Other", comment: "Other provider key")
        case .clientCertificate:
            return NSLocalizedString("""
            Client
            Certificate
            """, comment: "client certificate provider key")
        }
    }

    public func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    public func handleDidSelect(rowAt indexPath: IndexPath) {
        chosenAccountType = accountTypes[indexPath.row]
    }

    public func clientCertificateManagementViewModel() -> ClientCertificateManagementViewModel {
        // Client certificate handling will insert a client certificate into the given verifiable
        // account (hidden side effect), therefore from this point on it needs to be
        // persistent.
        verifiableAccount = verifiableAccount ?? VerifiableAccount.verifiableAccout(for: chosenAccountType)
        return ClientCertificateManagementViewModel(verifiableAccount: verifiableAccount)
       }

    public func loginViewModel() -> LoginViewModel {
        // If we handled certificates, then the verifiable account is already set and must be used.
        verifiableAccount = verifiableAccount ?? VerifiableAccount.verifiableAccout(for: chosenAccountType)
        return LoginViewModel(verifiableAccount: verifiableAccount)
       }
}
