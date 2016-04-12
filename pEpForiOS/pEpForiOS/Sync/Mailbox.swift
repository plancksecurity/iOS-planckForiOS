//
//  Mailbox.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
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

    init(folderName: String, emailAddress: String) {
        self.folderName = folderName
        self.emailAddress = emailAddress
    }

}
