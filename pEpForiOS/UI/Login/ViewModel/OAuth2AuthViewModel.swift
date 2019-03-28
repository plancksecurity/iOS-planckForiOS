//
//  OAuth2AuthViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 26.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Errors that are not directly reported by the used OAuth2 lib, but detected internally.
 */
enum OAuth2AuthViewModelError: Error {
    /**
     No configuration available for running the oauth2 request.
     */
    case noConfiguration

    /**
     The OAuth2 call yielded no token, but there was no error condition
     */
    case noToken

    /**
     The OAuth2 authorization was successful, but we lack the `lastOAuth2Parameters`
     for continuing login.
     */
    case noParametersForVerification
}

protocol OAuth2AuthViewModelDelegate: class {
    /**
     Called to signal an OAuth2 error.
     */
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?)
}

/**
 Handles OAuth2 authorization, including re-authorization.
 */
class OAuth2AuthViewModel {
    weak var delegate: OAuth2AuthViewModelDelegate?

    /**
     A strong reference is needed in order to guarantee the delegate will be called.
     */
    var currentAuthorizer: OAuth2AuthorizationProtocol?

    func authorize(authorizer: OAuth2AuthorizationProtocol, emailAddress: String,
                   viewController: UIViewController) {
        currentAuthorizer = authorizer
        if let theConfig = OAuth2Configuration.from(emailAddress: emailAddress) {
            currentAuthorizer?.delegate = self
            currentAuthorizer?.startAuthorizationRequest(
                viewController: viewController, oauth2Configuration: theConfig)
        } else {
            delegate?.didAuthorize(oauth2Error: OAuth2AuthViewModelError.noConfiguration,
                                   accessToken: nil)
        }
    }
}

extension OAuth2AuthViewModel: OAuth2AuthorizationDelegateProtocol {
    func authorizationRequestFinished(error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        delegate?.didAuthorize(oauth2Error: error, accessToken: accessToken)
    }
}
