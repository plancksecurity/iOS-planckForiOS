//
//  OAuth2Provider.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class OAuth2Provider: OAuth2ProviderProtocol {

    // MARK: - OAuth2AuthorizationFactoryProtocol

    var oauth2Authorizers = Set<OAuth2Authorization>()

    func createOAuth2Authorizer() -> OAuth2AuthorizationProtocol {
        let oauth2 = OAuth2Authorization()
        oauth2Authorizers.insert(oauth2)
        return oauth2
    }

    // MARK: - OAuth2AuthorizationURLHandlerProtocol

    func processAuthorizationRedirect(url: URL) -> Bool {
        var doneAuthorizerToRemove: OAuth2Authorization?

        for oauth in oauth2Authorizers {
            if oauth.processAuthorizationRedirect(url: url) {
                doneAuthorizerToRemove = oauth
                break
            }
        }
        if let theOne = doneAuthorizerToRemove {
            oauth2Authorizers.remove(theOne)
            return true
        }
        return false
    }
}
