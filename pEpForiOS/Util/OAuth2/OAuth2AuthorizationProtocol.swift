//
//  OAuth2AuthorizationProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

// We might want to distinguish error types.
enum OAuthErrorType {
    case inconsistentAuthorizationResult
}

/// The error that gets delegated when there was no error during authorization, but
/// neither a valid access token.
struct OAuth2AuthorizationError: LocalizedError {
    var errorDescription: String?
    var domain: String?
    var type: OAuthErrorType
    var errorMessage: String

    init(error: Error?) {
        self.domain = (error as? NSError)?.domain
        self.errorDescription = (error as? NSError)?.userInfo["NSUnderlyingError"] as? String
        self.type = .inconsistentAuthorizationResult
        let code = (error as? NSError)?.code ?? -1
        self.errorMessage = OAuth2AuthorizationError.getErrorMessage(code: code)
    }

    // Error messages are taken from documentation in OIDError.h
    // @see https://github.com/openid/AppAuth-iOS/blob/1.6.0/Source/AppAuthCore/OIDError.h
    static private func getErrorMessage(code: Int) -> String {
        switch code {
        case OIDErrorCode.invalidDiscoveryDocument.rawValue:
            return NSLocalizedString("A problem parsing an OpenID Connect Service Discovery document.", comment: "")
        case OIDErrorCode.userCanceledAuthorizationFlow.rawValue:
            return NSLocalizedString("The user manually canceled the OAuth authorization code flow.", comment: "")
        case OIDErrorCode.programCanceledAuthorizationFlow.rawValue:
            return NSLocalizedString("An OAuth authorization flow was programmatically cancelled.", comment: "")
        case OIDErrorCode.networkError.rawValue:
            return NSLocalizedString("A network error or server error occurred", comment: "")
        case OIDErrorCode.serverError.rawValue:
            return NSLocalizedString("A server error occurred", comment: "")
        case OIDErrorCode.jsonDeserializationError.rawValue:
            return NSLocalizedString("A problem occurred deserializing the response/JSON", comment: "")
        case OIDErrorCode.tokenResponseConstructionError.rawValue:
            return NSLocalizedString("A problem occurred constructing the token response from the JSON.", comment: "")
        case OIDErrorCode.safariOpenError.rawValue:
            return NSLocalizedString("UIApplication.openURL: returned NO when attempting to open the authorization request in mobile Safari.", comment: "")
        case OIDErrorCode.browserOpenError.rawValue:
            return NSLocalizedString("NSWorkspace.openURL returned NO when attempting to open the authorization request in the default browser", comment: "")
        case OIDErrorCode.tokenRefreshError.rawValue:
            return NSLocalizedString("A problem when trying to refresh the tokens ocurred", comment: "")
        case OIDErrorCode.registrationResponseConstructionError.rawValue:
            return NSLocalizedString("A problem occurred constructing the registration response from the JSON", comment: "")
        case OIDErrorCode.jsonSerializationError.rawValue:
            return NSLocalizedString("A problem occurred deserializing the response/JSON", comment: "")
        case OIDErrorCode.idTokenParsingError.rawValue:
            return NSLocalizedString("The ID Token did not parse.", comment: "")
        case OIDErrorCode.idTokenFailedValidationError.rawValue:
            return NSLocalizedString("The ID Token did not pass validation (e.g. issuer, audience checks).", comment: "")
        default:
            return NSLocalizedString("Unknown error occurred", comment: "")
        }
    }
}

/**
 A view controller that initiates an authorization request typically implements this.
 Since this is a delegate, derive from class so it can be used weakly.
 */
protocol OAuth2AuthorizationDelegateProtocol: AnyObject {
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
