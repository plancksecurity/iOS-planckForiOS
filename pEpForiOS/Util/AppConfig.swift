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
    var showedAccountsError: [String:Bool]

    let errorPropagator : ErrorPropagator

    ///For the views to kick off oauth2 requests.
    let oauth2AuthorizationFactory: OAuth2AuthorizationFactoryProtocol

    let keySyncHandshakeService: KeySyncHandshakeService

    let messageModelService: MessageModelServiceProtocol

    init(errorPropagator: ErrorPropagator,
         oauth2AuthorizationFactory: OAuth2AuthorizationFactoryProtocol,
         keySyncHandshakeService: KeySyncHandshakeService,
         messageModelService: MessageModelServiceProtocol) {
        self.errorPropagator = errorPropagator
        self.oauth2AuthorizationFactory = oauth2AuthorizationFactory
        self.keySyncHandshakeService = keySyncHandshakeService
        self.showedAccountsError = [:]
        self.messageModelService = messageModelService
    }
}
