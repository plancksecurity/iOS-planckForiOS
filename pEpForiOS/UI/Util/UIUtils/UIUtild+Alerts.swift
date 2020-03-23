//
//  UIUtild+Alerts.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

// MARK: - UIUtild+Alerts

extension UIUtils {

    /// Shows an alert with "OK" button only.
    /// - Parameters:
    ///   - title: alert title
    ///   - message: alert message
    ///   - completion: called when "OK" has been pressed
    static func showAlertWithOnlyPositiveButton(title: String?,
                                                message: String?,
                                                inNavigationStackOf viewController: UIViewController? = nil,
                                                completion: (()->Void)? = nil) {
        // Do not show alerts when app is in background.
        if UIApplication.shared.applicationState != .active {
            #if DEBUG
            // show alert in background when in debug.
            #else
            return
            #endif
        }
        let alertView = UIAlertController.pEpAlertController(title: title,
                                                             message: message,
                                                             preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment:
            "General alert positive button"),
                                     style: .default) { action in
                                        completion?()
        }
        alertView.addAction(okAction)
        guard let presenterVc = UIApplication.currentlyVisibleViewController(inNavigationStackOf: viewController) else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(alertView, animated: true, completion: nil)
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
        let alertView = UIAlertController.pEpAlertController(title: title,
                                                             message: message,
                                                             preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: positiveButtonText,
                                          style: .default) { (alertAction) in
                                            positiveButtonAction()
        })
        alertView.addAction(UIAlertAction(title: cancelButtonText,
                                          style: .cancel) { (alertAction) in
                                            cancelButtonAction()
        })

        guard let presenterVc = UIApplication.currentlyVisibleViewController(inNavigationStackOf: viewController) else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(alertView, animated: true, completion: nil)
    }
}
