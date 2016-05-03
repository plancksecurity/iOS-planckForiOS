//
//  ConnectionManager.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class ConnectionManager {
    public init() {}

    public func emailSyncConnection(connectInfo: ConnectInfo) -> ImapSync {
        let sync = ImapSync.init(connectInfo: connectInfo)
        return sync
    }

    public func smtpConnection(connectInfo: ConnectInfo) -> SmtpSend {
        // Don't cache
        return SmtpSend.init(connectInfo: connectInfo)
    }
}