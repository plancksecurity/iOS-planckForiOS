//
//  OAuth2ProviderProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 A complete implementation of OAuth2.
 */
protocol OAuth2ProviderProtocol:
OAuth2AuthorizationFactoryProtocol,
OAuth2AuthorizationURLHandlerProtocol {}
