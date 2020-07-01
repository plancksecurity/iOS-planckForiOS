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
    private static let newPassphraseEnteredCallback: (String) -> Void = { input in
        do {
            try PassphraseUtil().newPassphrase(input)
        } catch PassphraseUtil.PassphraseError.tooLong {
            Log.shared.info("Passphrase too long")
            showPassphraseTooLong()
        } catch {
            Log.shared.error("Something went wrong - It should not happen")
            showPassphraseWrongAlert()
        }
    }

    /// This callback attempts to register the new passphrase for new keys.
    /// If it fails because of its lenghts or due other reasons, it prompts to enter a new one.
    private static let newPassphraseEnteredForNewKeysCallback: (String) -> Void = { input in
        do {
            try PassphraseUtil().passphraseForNewKeys(input)
        } catch PassphraseUtil.PassphraseError.tooLong {
            Log.shared.info("Passphrase too long")
            showPassphraseForNewKeysTooLong()
        } catch {
            Log.shared.error("Something went wrong - It should not happen")
            showPassphraseWrongAlert()
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

//        showAlertWithTextfield(title: title, message: message, placeholder: placeholder,

        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
//        showAlertWithTextfield(title: title,
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
                               callback: newPassphraseEnteredCallback)
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
                               callback: newPassphraseEnteredCallback)
    }

}

// MARK : - Too long alerts

extension UIUtils {

    /// Shows an alert to inform the passphrase entered is too long and to require a new one.
    public static func showPassphraseForNewKeysTooLong(cancelCallback: (() -> Void)? = nil) {
        UIUtils.presentTooLongAlertView(with: newPassphraseEnteredForNewKeysCallback, cancelCallback: cancelCallback)
    }

    /// Shows an alert to inform the passphrase entered is too long and to require a new one.
    public static func showPassphraseTooLong(cancelCallback: (() -> Void)? = nil) {
        UIUtils.presentTooLongAlertView(with: newPassphraseEnteredCallback, cancelCallback: cancelCallback)
    }

    private static func presentTooLongAlertView(with callback: @escaping(_ input: String) -> (), cancelCallback: (() -> Void)? = nil) {
        let title = NSLocalizedString("Passphrase too long", comment: "Passphrase too long - title")
        let message = NSLocalizedString("Please enter one shorter", comment: "Please enter one shorter - message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
//        showAlertWithTextfield(title: title, message: message, placeholder: placeholder, callback: newPassphraseEnteredCallback)
        showAlertWithTextfield(identifier: .passphraseAlert,
                               title: title,
                               message: message,
                               placeholder: placeholder,
                               callback: newPassphraseEnteredCallback)
        showAlertWithTextfield(title: title, message: message, placeholder: placeholder, callback: callback, cancelCallback: cancelCallback)
    }

}
