//
//  ConnectionManager.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

public protocol ImapConnectionManagerProtocol {
    func imapConnection(connectInfo: EmailConnectInfo) -> ImapSync?
}

public protocol SmtpConnectionManagerProtocol {
    func smtpConnection(connectInfo: EmailConnectInfo) -> SmtpSend?
}

public protocol ConnectionManagerProtocol: ImapConnectionManagerProtocol,
SmtpConnectionManagerProtocol {}

open class ConnectionManager: ConnectionManagerProtocol {
    fileprivate let comp = "ConnectionManager"
    open var cacheImapConnections: Bool = false

    var imapConnections: [EmailConnectInfo: ImapSync] = [:]

    public init() {}

    deinit {
        closeAll()
    }

    open func imapConnection(connectInfo: EmailConnectInfo) -> ImapSync? {
        if cacheImapConnections {
            if let sync = imapConnections[connectInfo] {
                return sync
            }
        }

        let sync = ImapSync(connectInfo: connectInfo)

        if cacheImapConnections {
            imapConnections[connectInfo] = sync
        }

        return sync
    }

    open func smtpConnection(connectInfo: EmailConnectInfo) -> SmtpSend? {
        return SmtpSend(connectInfo: connectInfo)
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
