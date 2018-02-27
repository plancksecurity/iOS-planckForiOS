//
//  OAuth2ReAuthViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 26.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol OAuth2ReAuthViewModelErrorDelegate: class {
    /**
     Called to signal an OAuth2 error.
     */
    func handle(oauth2Error: Error)
}

/**
 Handles OAuth2 re-authorization.
 */
class OAuth2ReAuthViewModel {
    /**
     Must be set by the client to be able to 
     */
    var emailAddress: String?

    weak var delegate: OAuth2ReAuthViewModelErrorDelegate?

    func reOAuth2(authorizer: OAuth2AuthorizationProtocol, viewController: UIViewController) {
        var theAuthorizer = authorizer
        if let theConfig = OAuth2Configuration.from(emailAddress: emailAddress) {
            theAuthorizer.delegate = self
            theAuthorizer.startAuthorizationRequest(
                viewController: viewController, oauth2Configuration: theConfig)
        } else {
            delegate?.handle(oauth2Error: OAuth2InternalError.noConfiguration)
        }
    }
}

extension OAuth2ReAuthViewModel: OAuth2AuthorizationDelegateProtocol {
    func authorizationRequestFinished(error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        if let err = error {
            delegate?.handle(oauth2Error: err)
        } else {
            if let token = accessToken {
                // TODO: save
            } else {
                delegate?.handle(oauth2Error: OAuth2InternalError.noToken)
            }
        }
    }
}
