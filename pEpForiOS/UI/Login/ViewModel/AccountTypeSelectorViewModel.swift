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
    func didVerify(result: AccountVerificationResult)
    func handle(oauth2Error: Error)

}

class AccountTypeSelectorViewModel {
    /// Helper class to handle login logic via OAuth or manual input.
    var loginLogic = LoginLogic()

    private let clientCertificateUtil: ClientCertificateUtilProtocol

    public weak var delegate: AccountTypeSelectorViewModelDelegate?

    var chosenAccountType: VerifiableAccount.AccountType = .other

    init(clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
        self.clientCertificateUtil = clientCertificateUtil ?? ClientCertificateUtil()
        loginLogic.loginProtocolResponseDelegate = self
    }

    public func shouldShowClientCertificateButton() -> Bool {
        return clientCertificateUtil.listCertificates(session: nil).count > 0
    }

    public func handleDidChooseClientCertificate() {
        if clientCertificateUtil.listCertificates(session: nil).count == 0 {
            delegate?.showMustImportClientCertificateAlert()
        } else {
            chosenAccountType = .clientCertificate
            delegate?.showClientCertificateSeletionView()
        }
    }
    public func handleDiDChooseOAuth(viewController : UIViewController) {
        loginLogic.verifiableAccount = VerifiableAccount.verifiableAccount(for: chosenAccountType,
                                                                           usePEPFolderProvider: AppSettings.shared)
        loginLogic.loginWithOAuth2(viewController: viewController)


    }
    public func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    public func handleDidSelect(accountType: AccountType,
                                viewController : UIViewController? = nil) {
        switch accountType {
        case .google:
            chosenAccountType = .gmail
            handleDiDChooseOAuth(viewController: viewController!)
        case .microsoft:
            chosenAccountType = .o365
            handleDiDChooseOAuth(viewController: viewController!)
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

// MARK: - LoginProtocolResponseDelegate
//TODO Remove, this is a temporal fix
extension AccountTypeSelectorViewModel : LoginProtocolResponseDelegate {
    func didVerify(result: MessageModel.AccountVerificationResult) {
        delegate?.didVerify(result: result)
    }

    func handle(loginError: Error) {
    }

    func handle(oauth2Error: Error) {
        delegate?.handle(oauth2Error: oauth2Error)

    }
}
