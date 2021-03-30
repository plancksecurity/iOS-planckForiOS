//
//  OAuth2AuthorizationProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

/**
 The error that gets delegated when there was no error during authorization, but
 neither a valid access token.
 */
enum OAuth2AuthorizationError: Error {
    case inconsistentAuthorizationResult
}

/**
 A view controller that initiates an authorization request typically implements this.
 Since this is a delegate, derive from class so it can be used weakly.
 */
protocol OAuth2AuthorizationDelegateProtocol: class {
    func authorizationRequestFinished(error: Error?, accessToken: OAuth2AccessTokenProtocol?)
}

/**
 Typically used by a view controller that wants to initiate OAuth2
 authorization.
 */
protocol OAuth2AuthorizationProtocol {
    var delegate: OAuth2AuthorizationDelegateProtocol? { get set }

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
                                   oauth2Configuration: OAuth2ConfigurationProtocol)
}
