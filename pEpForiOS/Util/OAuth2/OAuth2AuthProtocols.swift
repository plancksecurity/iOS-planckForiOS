//
//  OAuth2Protocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Typically implemented by the app delegate, and made available to view controllers
 interested in OAuth2, e.g. via app config.
 For every oauth authorization object created, the app delegate must keep a reference to
 a corresponding OAuth2AuthorizationURLHandlerProtocol,
 so it can later correctly assign the redirect.
 */
protocol OAuth2AuthorizationFactoryProtocol {
    func createOAuth2Authorizer() -> OAuth2AuthorizationProtocol
}

struct OAuth2AccessToken {
    let accessToken: String
    let idToken: String
}

enum OAuth2AuthorizationError: Error {
    case inconsistentAuthorizationResult
}

/**
 A view controller that initiates an authorization request typically implements this.
 Since this is a delegate, derive from class so it can be used weakly.
 */
protocol OAuth2AuthorizationDelegateProtocol: class {
    func authorizationRequestFinished(error: Error?, accessToken: OAuth2AccessToken?)
}

/**
 The part of OAuth2 that a view controller sees, that wants to set it up.
 */
protocol OAuth2AuthorizationProtocol {
    weak var delegate: OAuth2AuthorizationDelegateProtocol? { get set }

    /**
     Trigger an authorization request. When it was successful, or on error,
     the delegate is invoked.
     - parameter viewController: The UIViewController that will be the parent of any
     browser interaction for signing in
     - parameter oauth2Type: The choice of OAuth2 (endpoint, provider) that you want to trigger
     - parameter scopes: The scopes to request authorization for. E.g., for gmail via
     IMAP/SMTP this is ["https://mail.google.com/"]
     */
    func startAuthorizationRequest(viewController: UIViewController,
                                   oauth2Type: OAuth2Type, scopes: [String])
}

/**
 The part that an application delegate interacts with.
 */
protocol OAuth2AuthorizationURLHandlerProtocol {
    /**
     Will try to match the given URL with the ongoing authorization.
     If there is a match, true is returned. Otherwise, that URL means something else.
     */
    func processAuthorizationRedirect(url: URL) -> Bool
}
