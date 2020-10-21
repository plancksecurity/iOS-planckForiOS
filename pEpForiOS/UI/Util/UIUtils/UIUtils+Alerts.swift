//
//  UIUtild+Alerts.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

// MARK: - UIUtild+Alerts

extension UIUtils {
    private static var alertPresenter: UIViewController {
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return UIViewController()
        }
        return presenterVc
    }

    /// Shows an alert with "OK" button only.
    /// - Parameters:
    ///   - title: alert title
    ///   - message: alert message
    ///   - completion: called when "OK" has been pressed
    static func showAlertWithOnlyPositiveButton(title: String?,
                                                message: String?,
                                                inNavigationStackOf viewController: UIViewController? = nil,
                                                completion: (()->Void)? = nil) {
        let alertViewController = UIAlertController.pEpAlertController(title: title,
                                                                       message: message,
                                                                       preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "General alert positive button"),
                                     style: .default) { action in
            completion?()
        }
        alertViewController.addAction(okAction)
        present(alertViewController)
    }
    
    static func showTwoButtonAlert(withTitle title: String,
                                   message: String,
                                   cancelButtonText: String = NSLocalizedString("Cancel",
                                                                                comment: "Default cancel button text"),
                                   positiveButtonText: String = NSLocalizedString("OK",
                                                                                  comment: "Default positive button text"),
                                   cancelButtonAction: @escaping ()->Void,
                                   positiveButtonAction: @escaping () -> Void,
                                   inNavigationStackOf viewController: UIViewController? = nil) {
        let alertViewController = UIAlertController.pEpAlertController(title: title,
                                                                       message: message,
                                                                       preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: positiveButtonText,
                                                    style: .default) { (alertAction) in
            positiveButtonAction()
        })
        alertViewController.addAction(UIAlertAction(title: cancelButtonText,
                                                    style: .cancel) { (alertAction) in
            cancelButtonAction()
        })
        present(alertViewController)
    }
    
    /// Generic method to show an alert and require information throught a textfield
    /// - Parameters:
    ///   - title: The title of the alert
    ///   - message: The message of the alert
    ///   - placeholder: The placeholder of the textfield
    ///   - positiveButtonText: text for positive button, defaults to "OK"
    ///   - negativeButtonText: text for negative button, defaults to Cancel""
    ///   - callback: A callback that takes the user input as parameter.
    ///   - cancelCallback: A callback that's executed when the user taps the cancel button.
    static func showAlertWithTextfield(identifier: IdentifiableAlertController.Identifier = .other,
                                       title: String,
                                       message: String,
                                       placeholder: String,
                                       positiveButtonText: String? = nil,
                                       negativeButtonText: String? = nil,
                                       negativeButtonStyle: UIAlertAction.Style = .cancel,
                                       callback: @escaping(_ input: String) -> (),
                                       cancelCallback: (() -> Void)? = nil) {
        let alertController = IdentifiableAlertController(identifier: identifier,
                                                          title: title,
                                                          message: message,
                                                          preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = placeholder
            textField.isSecureTextEntry = true
        }
        let okTitle = positiveButtonText ?? NSLocalizedString("OK", comment: "OK button title")
        let cancelTitle = negativeButtonText ?? NSLocalizedString("Cancel", comment: "OK button title")
        let action = UIAlertAction(title: okTitle,
                                   style: .default, handler: { [weak alertController] (_) in
            guard let alert = alertController, let textfields = alert.textFields else {
                Log.shared.errorAndCrash("Alert or textfields missing - This shoudn't happen")
                return
            }
            let textField = textfields[0]
            guard let passphrase = textField.text else { return }
                                    callback(passphrase)
        })
        alertController.addAction(action)
        let cancelAction: UIAlertAction =
            UIAlertAction(title: cancelTitle, style: negativeButtonStyle) { (action) in
                cancelCallback?()
        }
        alertController.addAction(cancelAction)
        present(alertController)
    }

    /// Present the pep alert if possible.
    /// - Parameter alertController: The controller to present.
    public static func present(_ alertController: PEPAlertViewController) {
        guard alertPresenter is PEPAlertViewController else {
            /// Valid case: there is an alert already shown
            return
        }
        DispatchQueue.main.async {
            alertPresenter.present(alertController, animated: true)
        }
    }

    private static func present(_ alertController: UIAlertController) {
        guard !UIApplication.isCurrentlyShowingAlert else {
            /// Valid case: there is an alert already shown
            return
        }
        DispatchQueue.main.async {
            alertPresenter.present(alertController, animated: true)
        }
    }
}
