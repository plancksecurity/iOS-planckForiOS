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

    /// Shows an alert with "OK" button only.
    /// - Parameters:
    ///   - title: alert title
    ///   - message: alert message
    ///   - completion: called when "OK" has been pressed
    public static func showAlertWithOnlyPositiveButton(title: String,
                                                message: String?,
                                                inNavigationStackOf viewController: UIViewController? = nil,
                                                style: AlertStyle = .default,
                                                completion: (()->Void)? = nil) {
        guard let alertViewController = UIUtils.getAlert(withTitle: title,
                                                   message: message,
                                                   positiveButtonAction: {
                                                    completion?()
                                                   },
                                                   inNavigationStackOf: viewController,
                                                   style: style,
                                                   numberOfButtons: .one) else {
            Log.shared.errorAndCrash("Can't instanciate alert")
            return
        }
        UIUtils.present(alertViewController)
    }

    public static func showTwoButtonAlert(withTitle title: String,
                                   message: String? = nil,
                                   cancelButtonText: String = NSLocalizedString("Cancel", comment: "Default cancel button text"),
                                   positiveButtonText: String = NSLocalizedString("OK", comment: "Default positive button text"),
                                   cancelButtonAction: (() -> Void)? = nil,
                                   positiveButtonAction: @escaping () -> Void,
                                   inNavigationStackOf viewController: UIViewController? = nil,
                                   style: AlertStyle) {
        guard let alertViewController = UIUtils.getAlert(withTitle: title,
                                                   message: message,
                                                   cancelButtonText: cancelButtonText,
                                                   positiveButtonText: positiveButtonText,
                                                   cancelButtonAction: cancelButtonAction,
                                                   positiveButtonAction: positiveButtonAction,
                                                   inNavigationStackOf: viewController,
                                                   style: style,
                                                   numberOfButtons: .two) else {
            Log.shared.errorAndCrash("Can't instanciate alert")
            return
        }
        UIUtils.present(alertViewController)
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
    public static func showAlertWithTextfield(identifier: IdentifiableAlertController.Identifier = .other,
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
}

// MARK: - UIUtils+ActionSheet

extension UIUtils {

    /// - Parameters:
    ///   - title: The title of the alert action
    ///   - style: The style of the alert action
    ///   - closure: The closure to be executed for the action.
    /// - Returns: An alert action.
    public static func action(_ title: String,
                       _ style: UIAlertAction.Style = .default,
                       _ closure: (() -> ())? = nil) ->  UIAlertAction {
        return UIAlertAction(title: title, style: style) { (action) in
            closure?()
        }
    }
    
    /// - Parameters:
    ///   - title: The title of the action sheet.
    ///   - message: The message of the action sheet
    /// - Returns: An action sheet with pEp green tint color.
    public static func actionSheet(title: String? = nil, message: String? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alertController.view.tintColor = .pEpGreen
        return alertController
    }
}

// MARK: - Private

extension UIUtils {
    private enum NumberOfButtons : Int {
        case one
        case two
    }

    /// Present the pep alert if possible.
    /// - Parameter alertController: The controller to present.
    private static func present(_ alertController: PEPAlertViewController) {
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }

        func shouldPresent() -> Bool {
            if let presenter = presenterVc as? PEPAlertViewController {
                if presenter.style == .warn && alertController.style == .warn {
                    return false
                }
            }
            return true
        }

        if shouldPresent() {
            DispatchQueue.main.async {
                presenterVc.present(alertController, animated: true)
            }
        }
    }

    private static func present(_ alertController: UIAlertController) {
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }

        guard !UIApplication.isCurrentlyShowingAlert else {
            /// Valid case: there is an alert already shown
            return
        }
        DispatchQueue.main.async {
            presenterVc.present(alertController, animated: true)
        }
    }

    private static func getAlert(withTitle title: String,
                          message: String? = nil,
                          cancelButtonText: String = NSLocalizedString("Cancel", comment: "Default cancel button text"),
                          positiveButtonText: String = NSLocalizedString("OK", comment: "Default positive button text"),
                          cancelButtonAction: (() -> Void)? = nil,
                          positiveButtonAction: @escaping () -> Void,
                          inNavigationStackOf viewController: UIViewController? = nil,
                          style: AlertStyle,
                          numberOfButtons: NumberOfButtons) -> PEPAlertViewController? {
        guard let pepAlertViewController = PEPAlertViewController.fromStoryboard(title: title, message: message, paintPEPInTitle: true) else {
                Log.shared.errorAndCrash("Fail to init PEPAlertViewController")
            return nil
        }
        var primaryColor: UIColor
        var secondaryColor: UIColor
        switch style {
        case .default:
            primaryColor = .pEpGreen
            secondaryColor = .pEpGreen
        case .warn:
            primaryColor = .pEpRed
            secondaryColor = .pEpGray
        }
        let positiveAction = PEPUIAlertAction(title: positiveButtonText, style: primaryColor) { _ in
            positiveButtonAction()
            pepAlertViewController.dismiss()
        }
        if numberOfButtons == .two {
            let cancelAction = PEPUIAlertAction(title: cancelButtonText, style: secondaryColor) { _ in
                cancelButtonAction?()
                pepAlertViewController.dismiss()
            }
            pepAlertViewController.add(action: cancelAction)
        }
        pepAlertViewController.add(action: positiveAction)
        pepAlertViewController.modalPresentationStyle = .overFullScreen
        pepAlertViewController.modalTransitionStyle = .crossDissolve
        return pepAlertViewController
    }
}

