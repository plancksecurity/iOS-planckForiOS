//
//  OAuth2Authorization.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension OAuth2AuthorizationConfig {
    func configurationOID() -> OIDServiceConfiguration {
        switch self {
        case .google:
            return OIDServiceConfiguration(
                authorizationEndpoint: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
                tokenEndpoint: URL(string: "https://www.googleapis.com/oauth2/v4/token")!)
        }
    }
}

/**
 Base implementation of OAuth2 authorization.
 */
class OAuth2Authorization: OAuth2AuthorizationProtocol {
    let kClientID = "uieauiaeiae"

    var currentAuthorizationFlow: OIDAuthorizationFlowSession?
    var authState: OIDAuthState?

    // MARK: - OAuth2AuthorizationProtocol

    weak var delegate: OAuth2AuthorizationDelegateProtocol?

    func startAuthorizationRequest(viewController: UIViewController,
                                   config: OAuth2AuthorizationConfig, scopes: [String]) {
        let redirectUrl = URL(string: "http://myLocalUrl")!

        let request = OIDAuthorizationRequest(
            configuration: config.configurationOID(),
            clientId: kClientID,
            clientSecret: nil,
            scopes: [OIDScopeOpenID, OIDScopeProfile],
            redirectURL: redirectUrl,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        currentAuthorizationFlow = OIDAuthState.authState(
        byPresenting: request, presenting: viewController) { [weak self] authState, error in
            self?.authState = nil
            if error != nil {
                self?.delegate?.authorizationRequestFinished(error: error, accessToken: nil)
            } else if authState != nil,
                let accessToken = authState?.lastTokenResponse?.accessToken,
                let idToken = authState?.lastTokenResponse?.idToken {
                self?.authState = authState
                self?.delegate?.authorizationRequestFinished(
                    error: error,
                    accessToken: OAuth2AccessToken(accessToken: accessToken, idToken: idToken))
            } else {
                self?.delegate?.authorizationRequestFinished(
                    error: OAuth2AuthorizationError.inconsistentAuthorizationResult,
                    accessToken: nil)
            }
        }
    }
}

extension OAuth2Authorization: OAuth2AuthorizationURLHandlerProtocol {
    func processAuthorizationRedirect(url: URL) -> Bool {
        guard let authFlow = currentAuthorizationFlow else {
            return false
        }
        if authFlow.resumeAuthorizationFlow(with: url) {
            self.currentAuthorizationFlow = nil
            return true
        }
        return false
    }
}
