//
//  AccountTypeSelectorViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

protocol AccountTypeSelectorViewModelDelegate: AnyObject {
    func showMustImportClientCertificateAlert()
    func showClientCertificateSeletionView()
}

class AccountTypeSelectorViewModel {
    private let clientCertificateUtil: ClientCertificateUtilProtocol

    public weak var delegate: AccountTypeSelectorViewModelDelegate?

    /// list of providers to show
    private var accountTypes = [VerifiableAccount.AccountType]()

    var chosenAccountType: VerifiableAccount.AccountType = .other

    init(clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
        self.clientCertificateUtil = clientCertificateUtil ?? ClientCertificateUtil()
        refreshAccountTypes()
    }

    //MB: - remove this.
    public func refreshAccountTypes() {
        accountTypes = [.icloud,
                        .o365,
                        .outlook,
                        .gmail,
                        .clientCertificate,
                        .other]
        if self.clientCertificateUtil.listCertificates(session: nil).count == 0 && accountTypes.contains(.clientCertificate) {
            guard let positionOfClientCert = accountTypes.firstIndex(of: .clientCertificate) else {
                Log.shared.errorAndCrash(message: "wrong data in accountTypes")
                return
            }
            accountTypes.remove(at: positionOfClientCert)
        }
    }

    public func handleDidChooseClientCertificate() {
        if clientCertificateUtil.listCertificates(session: nil).count == 0 {
            delegate?.showMustImportClientCertificateAlert()
        } else {
            chosenAccountType = .clientCertificate
            delegate?.showClientCertificateSeletionView()
        }
    }

    public func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    public func handleDidSelect(accountType: AccountType) {
        switch accountType {
        case .google:
            chosenAccountType = .gmail

        case .microsoft:
            chosenAccountType = .o365

        case .other:
            chosenAccountType = .other
        case .clientCertificate:
            chosenAccountType = .clientCertificate
            handleDidChooseClientCertificate()
        }
    }

    public func clientCertificateManagementViewModel() -> ClientCertificateManagementViewModel {
        return ClientCertificateManagementViewModel(verifiableAccount: verifiableAccountForCoosenAccountType(), shouldHideCancelButton: true)
    }

    public func loginViewModel() -> LoginViewModel {
        return LoginViewModel(verifiableAccount: verifiableAccountForCoosenAccountType())
    }
}

// MARK: - Private

extension AccountTypeSelectorViewModel {
    private func verifiableAccountForCoosenAccountType() -> VerifiableAccountProtocol {
        return VerifiableAccount.verifiableAccount(for: chosenAccountType, usePEPFolderProvider: AppSettings.shared)
    }
}
