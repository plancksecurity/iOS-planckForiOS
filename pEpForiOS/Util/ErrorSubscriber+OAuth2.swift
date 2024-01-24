//
//  ErrorSubscriber+OAuth2.swift
//  planckForiOS
//
//  Created by Dirk Zimmermann on 24/1/24.
//  Copyright © 2024 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import PlanckToolbox

extension ErrorSubscriber {
    func handleOAuth2AuthorizationError(error: Error) -> Bool {
        guard let displayError = DisplayUserError(withError: error) else {
            return false
        }

        func oauthType(scopes: [String]) -> OAuth2Type {
            let scopes = Set(scopes)

            // Note the default value, just in case.
            var oauthType = OAuth2Type.o365

            for authType in OAuth2Type.allCases {
                let configScopes = authType.oauth2Config()?.scopes ?? []
                let s1 = Set(configScopes)
                if !scopes.intersection(s1).isEmpty {
                    oauthType = authType
                    break
                }
            }

            return oauthType
        }

        func accountType(oauthType: OAuth2Type) -> VerifiableAccount.AccountType {
            switch oauthType {
            case .google: return VerifiableAccount.AccountType.gmail
            case .o365: return VerifiableAccount.AccountType.o365
            }
        }

        /// Handles the OAuth2 reauthorization
        func handleReauthorization(accountEmail: String, scopes: [String]) {
            if oauthAuthorizers[accountEmail] != nil {
                let oauthType = oauthType(scopes: scopes)
                let vc = UIApplication.currentlyVisibleViewController()
                let oauthAuthorizer = OAuthAuthorizer()
                oauthAuthorizers[accountEmail] = oauthAuthorizer
                oauthAuthorizer.delegate = self
                let oauth2Authorizer = OAuth2ProviderFactory().oauth2Provider().createOAuth2Authorizer()

                oauthAuthorizer.authorize(authorizer: oauth2Authorizer,
                                          accountType: accountType(oauthType: oauthType),
                                          viewController: vc)
            }
        }

        /// Presents the user a dialog with the error, giving him a choice of doing the reauthorization or not.
        func handleReauthorization(accountEmail: String, scope: String?) {
            let scopes = (scope ?? "").components(separatedBy: " ")
            if scopes.isEmpty {
                Log.shared.errorAndCrash(message: "A valid OAuth2 scope is needed on XOAuth2 errors")
                // Without a scope, we'll have to guess the OAuth2 provider, which is bad,
                // but it's O365 anyways, right?
            }

            func handleReAuth() {
                handleReauthorization(accountEmail: accountEmail, scopes: scopes)
            }

            UIUtils.showTwoButtonAlert(withTitle: displayError.title,
                                       message: displayError.errorDescription,
                                       positiveButtonAction: handleReAuth)
        }

        switch displayError.underlyingError {
        case ImapSyncOperationError.authenticationFailedXOAuth2(_, let accountEmail, let scope):
            handleReauthorization(accountEmail: accountEmail, scope: scope)
            return true
        default: return false
        }
    }
}

extension ErrorSubscriber: OAuthAuthorizerDelegate {
    func didAuthorize(oauth2Error: Error?, accessToken: MessageModel.OAuth2AccessTokenProtocol?) {
        if let token = accessToken, let email = accessToken?.getEmail()  {
            oauthAuthorizers.removeValue(forKey: email)
        }
    }
}
