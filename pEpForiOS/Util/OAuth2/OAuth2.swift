//
//  OAuth2.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class OAuth2 {
    var currentAuthorizationFlow: OIDAuthorizationFlowSession?
    var authState: OIDAuthState?

    func googleConfig() -> OIDServiceConfiguration {
        let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        let tokenEndpoint = URL(string: "https://www.googleapis.com/oauth2/v4/token")!
        return OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint,
                                       tokenEndpoint: tokenEndpoint)
    }

    func request(viewController: UIViewController) {
        let configuration = googleConfig()
        let kClientID = "uieauiaeiae"
        let kClientSecret = "uiaeuiaeuiaeuiae"

        let redirectUrl = URL(string: "http://myLocalUrl")!

        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: kClientID,
            clientSecret: kClientSecret,
            scopes: [OIDScopeOpenID, OIDScopeProfile],
            redirectURL: redirectUrl,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        currentAuthorizationFlow = OIDAuthState.authState(
        byPresenting: request, presenting: viewController) { [weak self] authState, error in
            self?.authState = nil
            if error != nil {
                // todo: communicate error
            } else if authState != nil {
                self?.authState = authState
            } else {
                // todo: communicate unknown error
            }
        }
    }

    func processRedirect(url: URL) -> Bool {
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
