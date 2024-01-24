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

        func oauthType(scopes: [String]) ->OAuth2Type {
            let scopes = Set(scopes)

            // Please note the default
            var oauthType = OAuth2Type.o365
            
            for authType in [OAuth2Type.google, OAuth2Type.o365] {
                let configScopes = authType.oauth2Config()?.scopes ?? []
                let s1 = Set(configScopes)
                if !scopes.intersection(s1).isEmpty {
                    oauthType = authType
                    break
                }
            }

            return oauthType
        }

        /// Handles the OAuth2 reauthorization
        func handleReauthorization(scopes: [String]) {
            let oauthType = oauthType(scopes: scopes)
            Log.shared.logInfo(message: "Have OAuth2 type: \(oauthType)")
        }

        /// Presents the user a dialog with the error, giving him a choice of doing the reauthorization or not.
        func handleReauthorization(accountEmail: String, scope: String?) {
            let scopes = (scope ?? "").components(separatedBy: " ")
            showTwoButtonAlert(withTitle: displayError.title,
                               message: displayError.errorDescription,
                               positiveButtonAction: { handleReauthorization(scopes: scopes) })
        }

        switch displayError.underlyingError {
        case ImapSyncOperationError.authenticationFailedXOAuth2(_, let accountEmail, let scope):
            handleReauthorization(accountEmail: accountEmail, scope: scope)
            return true
        default: return false
        }
    }
}
