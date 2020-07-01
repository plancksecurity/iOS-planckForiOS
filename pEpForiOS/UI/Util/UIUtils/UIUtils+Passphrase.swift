//
//  UIUtils+Passphrase.swift
//  pEp
//
//  Created by Martin Brude on 01/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension UIUtils {

    // MARK : - Callbacks

    /// This callback attempts to register the new passphrase.
    /// If it fails because of its lenghts or due other reasons, it prompts to enter a new one.
    private static func newPassphraseEnteredCallback(with cancelCallback: (()->Void)?) -> (String)->Void {
        return { input in
            do {
                try PassphraseUtil().newPassphrase(input)
            } catch PassphraseUtil.PassphraseError.tooLong {
                Log.shared.info("Passphrase too long")
                showPassphraseForNewKeysTooLong(cancelCallback: cancelCallback)
            } catch {
                Log.shared.error("Something went wrong - It should not happen")
                showPassphraseWrongAlert()
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

    // MARK : - Alerts

    /// Shows an alert to require a Passphrase for the new keys.
    public static func showUserPassphraseForNewKeysAlert(cancelCallback: (() -> Void)? = nil) {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("We recommend to use device encryption instead of using passphrases, because they're securing all data not only keys. In case you wan to use a passphrase anyway, please enter a passphrase here and enable it.", comment: "Passphrase message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")

        let task: (String) -> Void = { input in
            do {
                try PassphraseUtil().newPassphraseForNewKeys(input)
            } catch PassphraseUtil.PassphraseError.tooLong {
                Log.shared.info("Passphrase too long")
                showPassphraseForNewKeysTooLong(cancelCallback: cancelCallback)
            } catch {
                Log.shared.errorAndCrash("Something went wrong - It should not happen")
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
    public static func showPassphraseRequiredAlert() {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("Please enter the passphrase to continue", comment: "Passphrase message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
                               message: message,
                               placeholder: placeholder,
                               callback: newPassphraseEnteredCallback(with: nil))
    }

    /// Shows an alert to inform the passphrase entered is wrong and to require a new one.
    public static func showPassphraseWrongAlert() {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("The passphrase you entered is wrong. Please enter it again to continue", comment: "Passphrase message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
                               message: message,
                               placeholder: placeholder,
                               callback: newPassphraseEnteredCallback(with: nil))
    }
}

// MARK : - Too long alerts

extension UIUtils {

    /// Shows an alert to inform the passphrase entered is too long and to require a new one.
    public static func showPassphraseForNewKeysTooLong(cancelCallback: (() -> Void)? = nil) {
        UIUtils.presentTooLongAlertView(with: newPassphraseEnterForNewKeysCallback(with: cancelCallback), cancelCallback: cancelCallback)
    }

    /// Shows an alert to inform the passphrase entered is too long and to require a new one.
    public static func showPassphraseTooLong(cancelCallback: (() -> Void)? = nil) {
        UIUtils.presentTooLongAlertView(with: newPassphraseEnteredCallback(with: cancelCallback), cancelCallback: cancelCallback)
    }
}

// MARK : - Private

extension UIUtils {

    /// Presents an Alert View to inform the passphrase is too long.
    /// - Parameters:
    ///   - callback: The callback to be executed when the new one is submited
    ///   - cancelCallback: The callback to be executed when the user cancels the action
    private static func presentTooLongAlertView(with callback: @escaping(_ input: String) -> (), cancelCallback: (() -> Void)? = nil) {
        let title = NSLocalizedString("Passphrase too long", comment: "Passphrase too long - title")
        let message = NSLocalizedString("Please enter one shorter", comment: "Please enter one shorter - message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
                               message: message,
                               placeholder: placeholder,
                               callback: callback,
                               cancelCallback: cancelCallback)
    }
}
