//
//  OAuthAuthorizer.swift
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
enum OAuthAuthorizerError: Error {
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

protocol OAuthAuthorizerDelegate: AnyObject {
    /**
     Called to signal an OAuth2 error.
     */
    func didAuthorize(oauth2Error: Error?, accessToken: OAuth2AccessTokenProtocol?)
}

/**
 Handles OAuth2 authorization, including re-authorization.
 */
class OAuthAuthorizer {
    weak var delegate: OAuthAuthorizerDelegate?

    /**
     A strong reference is needed in order to guarantee the delegate will be called.
     */
    var currentAuthorizer: OAuth2AuthorizationProtocol?

    func authorize(authorizer: OAuth2AuthorizationProtocol,
                   emailAddress: String,
                   accountType: VerifiableAccount.AccountType,
                   viewController: UIViewController) {
        currentAuthorizer = authorizer
        let oauthType = OAuth2Type(accountType: accountType)
        if let theConfig = oauthType?.oauth2Config() {
            currentAuthorizer?.delegate = self
            currentAuthorizer?.startAuthorizationRequest(
                viewController: viewController, oauth2Configuration: theConfig)
        } else {
            delegate?.didAuthorize(oauth2Error: OAuthAuthorizerError.noConfiguration,
                                   accessToken: nil)
        }
    }
}

extension OAuthAuthorizer: OAuth2AuthorizationDelegateProtocol {
    func authorizationRequestFinished(error: Error?, accessToken: OAuth2AccessTokenProtocol?) {
        delegate?.didAuthorize(oauth2Error: error, accessToken: accessToken)
    }
}
