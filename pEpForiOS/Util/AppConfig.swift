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

    private var theSession: PEPSession?

    var session: PEPSession {
        get {
            guard let session = theSession else {
                Log.shared.errorAndCrash(component: #function, errorString: "No session!")
                return PEPSessionCreator.shared.newSession()
            }
            return session
        }
    }

    /**
     As soon as the UI has at least one account that is in use, this is set here.
     */
    var currentAccount: Account? = nil

    /**
     The UI can request key generation.
     */
    let mySelfer: KickOffMySelfProtocol

    init(session: PEPSession, mySelfer: KickOffMySelfProtocol,
         messageSyncService: MessageSyncServiceProtocol) {
        self.theSession = session
        self.messageSyncService = messageSyncService
        self.mySelfer = mySelfer
    }

    public func tearDownSession() {
        theSession = nil
    }
}
