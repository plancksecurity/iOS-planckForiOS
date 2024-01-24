//
//  UIUtils+OAuth2.swift
//  planckForiOS
//
//  Created by Dirk Zimmermann on 24/1/24.
//  Copyright © 2024 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import PlanckToolbox

extension UIUtils {
    static public func handleOAuth2AuthorizationError(error: Error) -> Bool {
        guard let displayError = DisplayUserError(withError: error) else {
            return false
        }

        /// Handles the OAuth2 reauthorization
        func handleReauthorization() {
            Log.shared.logInfo(message: "handleReauthorization")
        }

        /// Presents the user a dialog with the error, giving him a choice of doing the reauthorization or not.
        func handleReauthorization(accountEmail: String, scope: String?) {
            showTwoButtonAlert(withTitle: displayError.title,
                               message: displayError.errorDescription,
                               positiveButtonAction: handleReauthorization)
        }

        switch displayError.underlyingError {
        case ImapSyncOperationError.authenticationFailedXOAuth2(_, let accountEmail, let scope):
            handleReauthorization(accountEmail: accountEmail, scope: scope)
            return true
        default: return false
        }
    }
}
