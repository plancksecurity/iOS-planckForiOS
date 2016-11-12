//
//  Mailbox.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 A mailbox uniquely identifies an IMAP folder on a server.
 The server is identified by the emailAddress, the folder by its name.
 
 This is used for the UI interacting with the network components, e.g. when
 sending the message to the networking "user wants to open that folder and view it".
 */
class Mailbox: NSObject {
    let folderName: String
    let emailAddress: String

    init(emailAddress: String, folderName: String) {
        self.folderName = folderName
        self.emailAddress = emailAddress
    }

    convenience init(emailAddress: String) {
        self.init(emailAddress: emailAddress, folderName: ImapSync.defaultImapInboxName)
    }

    convenience init(connectInfo: EmailConnectInfo) {
        self.init(emailAddress: connectInfo.userName)
    }

}
