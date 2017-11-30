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
    let coreDataUtil: CoreDataUtil = CoreDataUtil()

    let messageSyncService: MessageSyncServiceProtocol

    let errorPropagator : ErrorPropagator
    /**
     As soon as the UI has at least one account that is in use, this is set here.
     */
    var currentAccount: Account? = nil

    /**
     The UI can request key generation.
     */
    let mySelfer: KickOffMySelfProtocol

    init(mySelfer: KickOffMySelfProtocol,
         messageSyncService: MessageSyncServiceProtocol,
         errorPropagator: ErrorPropagator) {
        self.messageSyncService = messageSyncService
        self.mySelfer = mySelfer
        self.errorPropagator = errorPropagator
    }
}
