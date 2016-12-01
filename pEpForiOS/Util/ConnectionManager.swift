//
//  ConnectionManager.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

open class ConnectionManager {
    fileprivate let comp = "ConnectionManager"
    open var cacheImapConnections: Bool = false

    var imapConnections: [EmailConnectInfo: ImapSync] = [:]
    weak var grandOperator: IGrandOperator!

    public init() {}

    deinit {
        closeAll()
    }

    open func emailSyncConnection(_ connectInfo: EmailConnectInfo) -> ImapSync {
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
    open func emailSyncConnectionOneWay(_ connectInfo: EmailConnectInfo) -> ImapSync {
        return ImapSync.init(connectInfo: connectInfo)
    }

    open func smtpConnection(_ connectInfo: EmailConnectInfo) -> SmtpSend {
        // Don't cache
        return SmtpSend.init(connectInfo: connectInfo)
    }

    /**
     Forcefully closes all cached connections. Useful during tests.
     */
    open func closeAll() {
        for (_, imap) in imapConnections {
            imap.close()
        }
        imapConnections.removeAll()
    }

    /**
     Tests will use this to make sure there are no retain cycles.
     */
    open func shutdown() {
        closeAll()
    }
}
