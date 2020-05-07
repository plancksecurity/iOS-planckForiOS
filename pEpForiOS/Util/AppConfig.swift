//
//  AppConfig.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

/**
 Some cross cutting concerns, like core data access, networking, etc.
 */
class AppConfig {
    ///For the views to kick off oauth2 requests.
    let oauth2AuthorizationFactory: OAuth2AuthorizationFactoryProtocol

    init(oauth2AuthorizationFactory: OAuth2AuthorizationFactoryProtocol) {
        self.oauth2AuthorizationFactory = oauth2AuthorizationFactory
    }
}
