//
//  AccountTypeSelectorViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import PlanckToolbox

protocol AccountTypeSelectorViewModelDelegate: AnyObject {
    func showMustImportClientCertificateAlert()
    func showClientCertificateSeletionView()
    func didVerify(result: AccountVerificationResult)
    func handle(error: Error)

}

class AccountTypeSelectorViewModel {
    /// Helper class to handle login logic via OAuth or manual input.
    var loginUtil = LoginUtil()

    private let clientCertificateUtil: ClientCertificateUtilProtocol

    public weak var delegate: AccountTypeSelectorViewModelDelegate?

    var chosenAccountType: VerifiableAccount.AccountType = .other

    init(clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
        self.clientCertificateUtil = clientCertificateUtil ?? ClientCertificateUtil()
        loginUtil.loginProtocolResponseDelegate = self
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
        loginUtil.verifiableAccount = VerifiableAccount.verifiableAccount(for: chosenAccountType,
                                                                          usePlanckFolderProvider: AppSettings.shared)
        loginUtil.loginWithOAuth2(viewController: viewController)


    }
    public func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    public func handleDidSelect(accountType: AccountType,
                                viewController : UIViewController? = nil) {
        switch accountType {
        case .google:
            chosenAccountType = .gmail
            guard let VC = viewController else {
                Log.shared.errorAndCrash("VC not found")
                return
            }
            handleDiDChooseOAuth(viewController: VC)
        case .microsoft:
            chosenAccountType = .o365
            guard let VC = viewController else {
                Log.shared.errorAndCrash("VC not found")
                return
            }
            handleDiDChooseOAuth(viewController: VC)
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
        return VerifiableAccount.verifiableAccount(for: chosenAccountType, usePlanckFolderProvider: AppSettings.shared)
    }
}

// MARK: - LoginProtocolResponseDelegate

extension AccountTypeSelectorViewModel : LoginProtocolResponseDelegate {
    func didVerify(result: MessageModel.AccountVerificationResult) {
        guard let unwrappedDelegate = delegate else {
            Log.shared.errorAndCrash(message: "Delegate not found")
            return
        }
        unwrappedDelegate.didVerify(result: result)
    }

    func didFail(error : Error) {
        guard let unwrappedDelegate = delegate else {
            Log.shared.errorAndCrash(message: "Delegate not found")
            return
        }
        unwrappedDelegate.handle(error: error)
    }
}
