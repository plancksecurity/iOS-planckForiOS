//
//  OAuth2Authorization.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Base implementation of OAuth2AuthorizationProtocol and OAuth2AuthorizationURLHandlerProtocol.
 */
class OAuth2Authorization: OAuth2AuthorizationProtocol {
    let uuid = Foundation.UUID()

    var currentAuthorizationFlow: OIDAuthorizationFlowSession?
    var authState: OIDAuthState?

    // MARK: - OAuth2AuthorizationProtocol

    weak var delegate: OAuth2AuthorizationDelegateProtocol?

    func startAuthorizationRequest(viewController: UIViewController,
                                   oauth2Configuration: OAuth2ConfigurationProtocol) {
        let request = OIDAuthorizationRequest(
            configuration: oauth2Configuration.oauth2Type.configurationOID(),
            clientId: oauth2Configuration.clientID,
            clientSecret: oauth2Configuration.clientSecret,
            scopes: oauth2Configuration.scopes,
            redirectURL: oauth2Configuration.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        currentAuthorizationFlow = OIDAuthState.authState(
        byPresenting: request, presenting: viewController) { [weak self] authState, error in
            if error == nil, let state = authState {
                self?.authState = state
                self?.delegate?.authorizationRequestFinished(
                    error: error,
                    accessToken: OAuth2AccessToken(authState: state, keyChainID: UUID().uuidString))
            } else {
                self?.authState = nil
                self?.delegate?.authorizationRequestFinished(
                    error: OAuth2AuthorizationError.inconsistentAuthorizationResult,
                    accessToken: nil)
            }
        }
    }
}

extension OAuth2Authorization: OAuth2AuthorizationURLHandlerProtocol {
    func processAuthorizationRedirect(url: URL) -> Bool {
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

extension OAuth2Authorization: Equatable {
    public static func ==(lhs: OAuth2Authorization, rhs: OAuth2Authorization) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension OAuth2Authorization: Hashable {

    func hash(into hasher: inout Hasher) {
        // `predicate.hashValue` is returning an unexpected value, that's why we use description.
        hasher.combine(uuid)
    }
}
