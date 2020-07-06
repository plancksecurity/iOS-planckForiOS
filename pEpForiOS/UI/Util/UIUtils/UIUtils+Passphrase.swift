//
//  UIUtils+Passphrase.swift
//  pEp
//
//  Created by Martin Brude on 01/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

// MARK: - UIUtils+Passphrase

extension UIUtils {

    /// Shows an alert to input a passphrase for the new keys.
    public static func showPassphraseInputForNewKeys(cancelCallback: (() -> Void)? = nil) {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("We recommend to use device encryption instead of using passphrases, because they're securing all data, not only keys. In case you want to use a passphrase anyway, please enter a passphrase here and enable it.",
                                        comment: "Passphrase message")
        let placeholder = NSLocalizedString("Passphrase",
                                            comment: "Passphrase placeholder")

        let task: (String) -> Void = { input in
            do {
                try PassphraseUtil().newPassphraseForNewKeys(input)
            } catch PassphraseUtil.PassphraseError.tooLong {
                Log.shared.info("Passphrase too long")
                showPassphraseForNewKeysTooLong(cancelCallback: cancelCallback)
            } catch {
                Log.shared.errorAndCrash("Unhandled error")
            }
        }
        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
                               message: message,
                               placeholder: placeholder,
                               callback: task,
                               cancelCallback: cancelCallback)
    }

    /// Shows an alert to require a Passphrase
    public static func showPassphraseRequiredAlert(completion: ((Success)->Void)? = nil) {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("Please enter the passphrase to continue",
                                        comment: "Passphrase message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
        var cancelBlock: (()->Void)?
        if let _ = completion {
            cancelBlock = {
                completion?(false)
            }
        }
        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
                               message: message,
                               placeholder: placeholder,
                               callback: newPassphraseEnteredCallback(completion: completion),
                               cancelCallback: cancelBlock)
    }
}

// MARK: - Private

extension UIUtils {

    /// Shows an alert to inform the passphrase entered is wrong and to require a new one.
    /// Imntentionally internal. UIUtils.swift needs it, sould not be (but is) visible for the rest of the app.
    static func showPassphraseWrongAlert() {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("The passphrase you entered is wrong. Please enter it again to continue",
                                        comment: "Passphrase message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
                               message: message,
                               placeholder: placeholder,
                               callback: newPassphraseEnteredCallback())
    }

    /// Shows an alert to inform the passphrase entered is too long and to require a new one.
    private static func showPassphraseForNewKeysTooLong(cancelCallback: (() -> Void)? = nil) {
        UIUtils.presentTooLongAlertView(withInputHandler: newPassphraseEnterForNewKeysCallback(with: cancelCallback),
                                        cancelBlock: cancelCallback)
    }

    /// Presents an Alert View to inform the passphrase is too long.
    /// - Parameters:
    ///   - handleInputBlock: called when the user typed in a new password, passing the PW as `input` param.
    ///   - cancelBlock: The callback to be executed when the user cancels the action
    private static func presentTooLongAlertView(withInputHandler handleInputBlock: @escaping(_ input: String) -> (),
                                                cancelBlock: (() -> Void)? = nil) {
        let title = NSLocalizedString("Passphrase too long", comment: "Passphrase too long - title")
        let message = NSLocalizedString("Please enter one shorter", comment: "Please enter one shorter - message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
                               message: message,
                               placeholder: placeholder,
                               callback: handleInputBlock,
                               cancelCallback: cancelBlock)
    }

    // MARK: Callbacks

    /// This callback attempts to register the new passphrase.
    /// If it fails because of its lenghts or due other reasons, it prompts to enter a new one.
    private static func newPassphraseEnteredCallback(withCancelBlock cancelCallback: (()->Void)? = nil,
                                                     completion: ((Success)->Void)? = nil) -> (String)->Void {
        let inputhandlerCallingCompletion: ((String)->Void) = { input in
            completion?(true)
        }

        let cancelBlockAlsoHandlingCompletion = {
            cancelCallback?()
            completion?(false)
        }
        return { input in
            do {
                try PassphraseUtil().newPassphrase(input)
                completion?(true)
            } catch PassphraseUtil.PassphraseError.tooLong {
                Log.shared.info("Passphrase too long")
                presentTooLongAlertView(withInputHandler: inputhandlerCallingCompletion,
                                        cancelBlock: cancelBlockAlsoHandlingCompletion)
            } catch {
                Log.shared.errorAndCrash("Unhandled error")
                completion?(false)
            }
        }
    }

    /// This callback attempts to register the new passphrase for new keys.
    /// If it fails because of its lenghts or due other reasons, it prompts to enter a new one.
    private static func newPassphraseEnterForNewKeysCallback(with cancelCallback: (()->Void)?) -> (String)->Void {
        return { input in
            do {
                try PassphraseUtil().newPassphraseForNewKeys(input)
            } catch PassphraseUtil.PassphraseError.tooLong {
                Log.shared.info("Passphrase too long")
                showPassphraseForNewKeysTooLong(cancelCallback: cancelCallback)
            } catch {
                Log.shared.error("Something went wrong - It should not happen")
                showPassphraseWrongAlert()
            }
        }
    }
}
