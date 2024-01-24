//
//  UIUtils+ShowError.swift
//  pEp
//
//  Created by Dirk Zimmermann on 10.02.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

import PlanckToolbox

extension UIUtils {
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
                let currentlyShownViewController = UIApplication.currentlyVisibleViewController()
                if (displayError.type == .brokenServerConnectionSmtp ||
                    displayError.type == .brokenServerConnectionImap) {
                    if (currentlyShownViewController is EmailListViewController || currentlyShownViewController is ComposeViewController) {
                        UIUtils.showServerNotAvailableBanner()
                    }
                } else {
                    let handled = handleOAuth2AuthorizationError(error: error)
                    if !handled {
                        showAlertWithOnlyPositiveButton(title: displayError.title, message: displayError.errorDescription)
                    }
                }
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
}
