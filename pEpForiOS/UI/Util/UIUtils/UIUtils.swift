//
//  UIUtils.swift
//  pEp
//pde
//  Created by Andreas Buff on 29.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import ContactsUI

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

import pEpIOSToolbox

class UIUtils {

    /// Converts the error to a user frienldy DisplayUserError and presents it to the user
    ///
    /// - Parameters:
    ///   - error: error to preset to user
    static public func show(error: Error) {
        let workBlock = {
            // Do not show alerts when app is in background.
            if UIApplication.shared.applicationState != .active {
                #if DEBUG
                // show alert in background when in debug.
                #else
                return
                #endif
            }

            Log.shared.info("May or may not display error to user: (interpolate) %@", "\(error)")

            guard let displayError = DisplayUserError(withError: error) else {
                // Do nothing. The error type is not suitable to bother the user with.
                return
            }
            DispatchQueue.main.async {
                showAlertWithOnlyPositiveButton(title: displayError.title, message: displayError.errorDescription)
            }
        }

        if Thread.current == Thread.main {
            workBlock()
        } else {
            DispatchQueue.main.async {
                workBlock()
            }
        }
    }

    /// Shows the navigation controller passed by parameter
    /// - Parameter navigationController: The Navigation Controller to present.
    public static func show(navigationController: UINavigationController) {
        let presenterVc = UIApplication.currentlyVisibleViewController()
        presenterVc.present(navigationController, animated: true)
    }

}
