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
    let messageSyncService: MessageSyncServiceProtocol

    var showedAccountsError: [String:Bool]

    let errorPropagator : ErrorPropagator

    /**
     The UI can request key generation.
     */
    let mySelfer: KickOffMySelfProtocol

    /**
     For the views to kick off oauth2 requests.
     */
    let oauth2AuthorizationFactory: OAuth2AuthorizationFactoryProtocol

    init(mySelfer: KickOffMySelfProtocol,
         messageSyncService: MessageSyncServiceProtocol,
         errorPropagator: ErrorPropagator,
         oauth2AuthorizationFactory: OAuth2AuthorizationFactoryProtocol) {
        self.messageSyncService = messageSyncService
        self.mySelfer = mySelfer
        self.errorPropagator = errorPropagator
        self.oauth2AuthorizationFactory = oauth2AuthorizationFactory
        self.showedAccountsError = [:]
    }
}
