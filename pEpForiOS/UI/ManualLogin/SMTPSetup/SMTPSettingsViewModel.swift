//
//  SMTPSettingsViewModel.swift
//  pEp
//
//  Created by Martín Brude on 4/7/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import PlanckToolbox

protocol SMTPSettingsDelegate: AnyObject {

    /// Hide keyboard
    func hideKeyboard()

    /// Update view state from view model
    /// - Parameter animated: this property only apply to  items with animations, list AnimatedPlaceholderTextFields
    func updateView(animated: Bool)

    /// Inform a message to the user
    ///
    /// - Parameters:
    ///   - message: The message to shown
    ///   - title: The title
    func inform(message: String, title: String)

    /// The account was successfully verified
    func accountVerifiedSuccessfully()

    /// Show an error message to the user
    /// - Parameter error: The error to show
    func showError(error: Error)
}

class SMTPSettingsViewModel {

    init(delegate: SMTPSettingsDelegate, verifiableAccount: VerifiableAccountProtocol) {
        self.delegate = delegate
        self.verifiableAccount = verifiableAccount
    }

    public weak var delegate: SMTPSettingsDelegate?

    public var verifiableAccount: VerifiableAccountProtocol

    public var isCurrentlyVerifying: Bool = false {
        didSet {
            delegate?.updateView(animated: true)
        }
    }

    public func handleLoading() {
        if isCurrentlyVerifying {
            LoadingInterface.showLoadingInterface()
        } else {
            LoadingInterface.removeLoadingInterface()
        }
    }

    public func handleDidPressNextButton() {
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("Delegate not found")
            return
        }
        do {
            try verifyAccount()
            delegate.hideKeyboard()
        } catch {
            let errorTitle = NSLocalizedString("Empty Field", comment: "Title of alert: a required field is empty")
            isCurrentlyVerifying = false
            var errorMessage = ""
            if let verifiableError = error as? VerifiableAccountValidationError {
                switch verifiableError {
                case .invalidUserData:
                    errorMessage = NSLocalizedString("Some mandatory fields are empty",
                                                     comment: "Message of alert: a required field is empty")
                case .unknown:
                    errorMessage = NSLocalizedString("Something went wrong.",
                                                     comment: "Message of alert: something went wrong.")
                }
            } else {
                errorMessage = error.localizedDescription
            }
            delegate.inform(message: errorMessage, title: errorTitle)
        }
    }

    /// Triggers verification for given data.
    ///
    /// - Throws: AccountVerificationError
    private func verifyAccount() throws {
        isCurrentlyVerifying = true
        verifiableAccount.verifiableAccountDelegate = self
        try verifiableAccount.verify()
    }
}

extension SMTPSettingsViewModel: VerifiableAccountDelegate {

    func didEndVerification(result: Result<Void, Error>) {
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("Delegate not found")
            return
        }

        switch result {
        case .success:
            verifiableAccount.save(completion: { [weak self] (savingResult) in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    return
                }
                DispatchQueue.main.async {
                    switch savingResult {
                    case .success:
                        me.isCurrentlyVerifying = false
                        delegate.accountVerifiedSuccessfully()
                    case .failure(_):
                        me.isCurrentlyVerifying = false
                        delegate.showError(error: VerifiableAccountValidationError.invalidUserData)
                    }
                }
            })

        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    return
                }
                me.isCurrentlyVerifying = false
                delegate.showError(error: error)
            }
        }
    }
}
