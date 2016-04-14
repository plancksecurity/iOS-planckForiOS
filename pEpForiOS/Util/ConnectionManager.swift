//
//  ConnectionManager.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class ConnectionManager {
    private var emailSyncConnections: [ConnectInfo:Service] = [:]
    private let coreDataUtil: CoreDataUtil

    init(coreDataUtil: CoreDataUtil) {
        self.coreDataUtil = coreDataUtil
    }

    func emaiSyncConnection(connectInfo: ConnectInfo) -> ImapSync {
        if let service = emailSyncConnections[connectInfo] {
            return service as! ImapSync
        } else {
            let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: connectInfo)
            emailSyncConnections[connectInfo] = sync
            return sync
        }
    }

    func smtpConnection(connectInfo: ConnectInfo) -> SmtpSend {
        // Don't cache
        return SmtpSend.init(coreDataUtil: coreDataUtil, connectInfo: connectInfo)
    }
}