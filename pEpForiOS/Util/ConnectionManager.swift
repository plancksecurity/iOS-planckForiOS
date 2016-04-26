//
//  ConnectionManager.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class ConnectionManager {
    private var emailSyncConnections: [ConnectInfo:Service] = [:]
    private let coreDataUtil: ICoreDataUtil

    public init(coreDataUtil: ICoreDataUtil) {
        self.coreDataUtil = coreDataUtil
    }

    public func emaiSyncConnection(connectInfo: ConnectInfo) -> ImapSync {
        if let service = emailSyncConnections[connectInfo] {
            return service as! ImapSync
        } else {
            let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: connectInfo)
            emailSyncConnections[connectInfo] = sync
            return sync
        }
    }

    public func smtpConnection(connectInfo: ConnectInfo) -> SmtpSend {
        // Don't cache
        return SmtpSend.init(coreDataUtil: coreDataUtil, connectInfo: connectInfo)
    }
}