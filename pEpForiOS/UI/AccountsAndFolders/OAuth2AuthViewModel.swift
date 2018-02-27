//
//  OAuth2AuthViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 26.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol OAuth2AuthViewModelDelegate: class {
    /**
     Called to signal an OAuth2 error.
     */
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?)
}

/**
 Handles OAuth2 re-authorization.
 */
class OAuth2AuthViewModel {
    weak var delegate: OAuth2AuthViewModelDelegate?

    func authorize(authorizer: OAuth2AuthorizationProtocol, emailAddress: String,
                   viewController: UIViewController) {
        var theAuthorizer = authorizer
        if let theConfig = OAuth2Configuration.from(emailAddress: emailAddress) {
            theAuthorizer.delegate = self
            theAuthorizer.startAuthorizationRequest(
                viewController: viewController, oauth2Configuration: theConfig)
        } else {
            delegate?.didAuthorize(oauth2Error: OAuth2InternalError.noConfiguration,
                                   accessToken: nil)
        }
    }
}

extension OAuth2AuthViewModel: OAuth2AuthorizationDelegateProtocol {
    func authorizationRequestFinished(error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        delegate?.didAuthorize(oauth2Error: error, accessToken: accessToken)
    }
}
