//
//  UIUtils+Passphrase.swift
//  pEp
//
//  Created by Martin Brude on 01/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - Passphrase Dialogs for using a key with  Passphrase (PASSPHRASE_REQUIRED)

extension UIUtils {

    /// Shows an alert to require a Passphrase
    static public func showPassphraseRequiredAlert(completion: ((String?)->Void)? = nil) {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("Please enter the passphrase to continue",
        comment: "Passphrase message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")

        showPassphraseInputAlert(title: title,
                                 message: message,
                                 placeholder: placeholder,
                                 completion: completion)
    }

    /// Shows an alert to require a Passphrase
    static public func showPassphraseRequiredForPEPSyncAlert(completion: ((String?)->Void)? = nil) {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("Enter passphrase for p≡p Sync:",
                                        comment: "Enter passphrase alert - message - shown while pEp sync is running")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
        let cancelButtonText = NSLocalizedString("Shutdown p≡p Sync",
                                                 comment: "Enter passphrase alert - Negative button text - shown while pEp sync is running")
        showPassphraseInputAlert(title: title,
                                 message: message,
                                 placeholder: placeholder,
                                 negativeButtonText: cancelButtonText,
                                 negativeButtonStyle: .destructive,
                                 completion: completion)
    }

    /// Shows an alert to inform the passphrase entered is wrong and to require a new one.
    static public func showWrongPassphraseAlert(completion: ((String?)->Void)? = nil) {
        let title = NSLocalizedString("Passphrase", comment: "Passphrase title")
        let message = NSLocalizedString("The passphrase you entered is wrong. Please enter it again to continue",
                                        comment: "Passphrase message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")

        showPassphraseInputAlert(title: title, message: message,
                                 placeholder: placeholder,
                                 completion: completion)
    }

    /// Shows an alert to inform the passphrase entered is too long and to require a new one.
    static private func showPassphraseTooLongAlert(completion: ((String?)->Void)? = nil) {
        let title = NSLocalizedString("Passphrase too long", comment: "Passphrase too long - title")
        let message = NSLocalizedString("Please enter one shorter", comment: "Please enter one shorter - message")
        let placeholder = NSLocalizedString("Passphrase", comment: "Passphrase placeholder")
        showPassphraseInputAlert(title: title,
                                 message: message,
                                 placeholder: placeholder,
                                 completion: completion)
    }

    // MARK: Private

    static private func showPassphraseInputAlert(title: String,
                                                 message: String,
                                                 placeholder: String,
                                                 positiveButtonText: String? = nil,
                                                 negativeButtonText: String? = nil,
                                                 negativeButtonStyle: UIAlertAction.Style = .cancel,
                                                 completion: ((String?)->Void)?) {
        let callback:(String)->Void = { input in
            completion?(input)
        }
        let cancelCallback:()->Void = {
            completion?(nil)
        }
        DispatchQueue.main.async {
            guard !isCurrentlyShowingPassphraseInputAlert else {
                // A passphrase alert is already shown. Do not display onother one on top of it.
                // Do nothing instead ...
                cancelCallback()
                return
            }
            showAlertWithTextfield(identifier: .passphraseAlert,
                                   title: title,
                                   message: message,
                                   placeholder: placeholder,
                                   positiveButtonText: positiveButtonText,
                                   negativeButtonText: negativeButtonText,
                                   negativeButtonStyle: negativeButtonStyle,
                                   callback: callback,
                                   cancelCallback: cancelCallback)
        }
    }

    /// Whether or not a passphrase related alert is currently shown.
    /// - note: Must be called on the main queue!
    static private var isCurrentlyShowingPassphraseInputAlert: Bool {
        var result = false
        guard let topVC = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC shown?")
            return result
        }
        if let shownIdentifiableAlertController = topVC as? IdentifiableAlertController {
            if shownIdentifiableAlertController.identifier == .passphraseAlert {
                result = true
            }
        }
        return result
    }
}

// MARK: - Passphrase Dialogs for setting up a passphrase for new keys

extension UIUtils {

    /// Shows an alert to require a Passphrase for the new keys.
    public static func showUserPassphraseForNewKeysAlert(cancelCallback: (() -> Void)? = nil) {
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

    // MARK: Private

    /// Shows an alert to inform the passphrase entered is too long and to require a new one.
    private static func showPassphraseForNewKeysTooLong(cancelCallback: (() -> Void)? = nil) {
        UIUtils.presentTooLongForNewKeysAlertView(withInputHandler: newPassphraseEnterForNewKeysCallback(with: cancelCallback), cancelBlock: cancelCallback)
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
                showWrongPassphraseAlert()
            }
        }
    }

    //BUFF: thats duplicated code (localised strings) for enter PP and enterPPForNewKeys. Cleanup.
    /// Presents an Alert View to inform the passphrase is too long.
    /// - Parameters:
    ///   - handleInputBlock: called when the user typed in a new password, passing the PW as `input` param.
    ///   - cancelBlock: The callback to be executed when the user cancels the action
    private static func presentTooLongForNewKeysAlertView(withInputHandler handleInputBlock: @escaping(_ input: String) -> (),
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
}
