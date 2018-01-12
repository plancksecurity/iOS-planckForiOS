//
//  OAuth2AccessToken.swift
//  pEp
//
//  Created by Dirk Zimmermann on 12.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Result of an OAuth2 authorization request. Persist this, and invoke it anytime you need
 fresh tokens.
 */
class OAuth2AccessToken: OAuth2AccessTokenProtocol {
    let authState: OIDAuthState

    init(authState: OIDAuthState) {
        self.authState = authState
    }

    func performAction(
        freshTokensBlock: @escaping (_ error: Error?, _ accessToken: String?) -> Void) {
        authState.performAction() { accessToken, idToken, error in
            freshTokensBlock(error, accessToken)
        }
    }
}
