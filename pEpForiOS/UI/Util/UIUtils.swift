//
//  UIUtils.swift
//  pEp
//
//  Created by Andreas Buff on 29.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

struct UIUtils {
    
    /// Converts the error to a user frienldy DisplayUserError and presents it to the user
    ///
    /// - Parameters:
    ///   - error: error to preset to user
    ///   - vc: ViewController to present the error on
    static func show(error: Error, inViewController vc: UIViewController) {
        Log.shared.errorComponent(#function, message: "Will display error to user: \(error)")
        guard let displayError = DisplayUserError(withError: error) else {
            // Do nothing. The error type is not suitable to bother the user with.
            return
        }
        showAlertWithOnlyPositiveButton(title: displayError.title,
                                        message: displayError.errorDescription,
                                        inViewController: vc)
    }

    static func showAlertWithOnlyPositiveButton(title: String?, message: String?,
                                                inViewController vc: UIViewController) {
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
        alertView.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:
            "General alert positive button"),
                                          style: .default,
                                          handler: nil))
        vc.present(alertView, animated: true, completion: nil)
    }
}
