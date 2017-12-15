//
//  OAuth2AuthorizationFactoryProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Typically made available to view clients, so they can get access to an
 implementation of the OAuth2AuthorizationProtocol in order to start
 OAuth2 authorization requests.
 */
protocol OAuth2AuthorizationFactoryProtocol {
    func createOAuth2Authorizer() -> OAuth2AuthorizationProtocol
}
