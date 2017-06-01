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
class AppConfig: NSObject {
    let coreDataUtil: CoreDataUtil = CoreDataUtil()
    let connectionManager = ConnectionManager()
    let messageSyncService: MessageSyncServiceProtocol

    private var theSession: PEPSession?

    var session: PEPSession {
        get {
            if theSession == nil {
                theSession = PEPSession()
            }
            return theSession ?? PEPSession()
        }
        set {
            theSession = newValue
        }
    }

    /**
     As soon as the UI has at least one account that is in use, this is set here.
     */
    var currentAccount: Account? = nil

    init(session: PEPSession, messageSyncService: MessageSyncServiceProtocol) {
        self.theSession = session
        self.messageSyncService = messageSyncService
    }

    public func tearDownSession() {
        theSession = nil
    }
}
