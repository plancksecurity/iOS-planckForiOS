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

    public weak var delegate: AccountTypeSelectorViewModelDelegate?

    /// list of providers to show
    private let accountTypes: [VerifiableAccount.AccountType] = [.gmail,
                                                                 .o365,
                                                                 .icloud,
                                                                 .outlook,
                                                                 .aol,
                                                                 .clientCertificate,
                                                                 .other]

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
        case .o365:
            return "asset-Office365"
        case .icloud:
            return "asset-iCloud"
        case .outlook:
            return "asset-Outlook"
        case .aol:
            return "asset-Aol"
        }
    }

    public func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    public func handleDidSelect(rowAt indexPath: IndexPath) {
        chosenAccountType = accountTypes[indexPath.row]
    }

    public func clientCertificateManagementViewModel() -> ClientCertificateManagementViewModel {
        return ClientCertificateManagementViewModel(verifiableAccount: VerifiableAccount.verifiableAccout(for: chosenAccountType))
    }

    public func loginViewModel() -> LoginViewModel {
        return LoginViewModel(verifiableAccount: VerifiableAccount.verifiableAccout(for: chosenAccountType))
    }
}
