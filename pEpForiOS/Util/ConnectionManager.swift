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
