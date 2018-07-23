//
//  ConnectionManager.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

protocol ImapConnectionManagerProtocol {
    func imapConnection(connectInfo: EmailConnectInfo) -> ImapSync?
}

protocol SmtpConnectionManagerProtocol {
    func smtpConnection(connectInfo: EmailConnectInfo) -> SmtpSend?
}

protocol ConnectionManagerProtocol: ImapConnectionManagerProtocol, SmtpConnectionManagerProtocol {}
