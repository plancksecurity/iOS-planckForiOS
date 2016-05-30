//
//  ConnectionManager.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class ConnectionManager {
    private let comp = "ConnectionManager"
    public var cacheImapConnections: Bool = true

    var imapConnections: [ConnectInfo: ImapSync] = [:]

    public init() {}

    deinit {
        closeAll()
    }

    public func emailSyncConnection(connectInfo: ConnectInfo) -> ImapSync {
        if cacheImapConnections {
            if let sync = imapConnections[connectInfo] {
                return sync
            }
        }

        let sync = ImapSync.init(connectInfo: connectInfo)

        if cacheImapConnections {
            imapConnections[connectInfo] = sync
        }

        return sync
    }

    /**
     - Returns: A one-way/throw-away IMAP sync connection, e.g., for testing/verifying
      a connection.
     */
    public func emailSyncConnectionOneWay(connectInfo: ConnectInfo) -> ImapSync {
        return ImapSync.init(connectInfo: connectInfo)
    }

    public func smtpConnection(connectInfo: ConnectInfo) -> SmtpSend {
        // Don't cache
        return SmtpSend.init(connectInfo: connectInfo)
    }

    /**
     Forcefully closes all cached connections. Useful during tests.
     */
    public func closeAll() {
        for (_, imap) in imapConnections {
            imap.close()
        }
        imapConnections.removeAll()
    }
}