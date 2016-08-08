//
//  EncryptionData.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

/**
 Contains all data that is needed for encrypting and sending emails.
 By sourcing out all needed data, it becomes possible to chain operations, like
 one for encrypting, one for sending the mails,
 and one for persisting the result on the IMAP server.
 */
public class EncryptionData {
    /**
     Needed for accessing core data.
     */
    let coreDataUtil: ICoreDataUtil

    /**
     For getting a SMTP connection.
     */
    let connectionManager: ConnectionManager

    /**
     The original unencrypted message ID. Needed as an object ID so it can be passed
     between operations.
     */
    let coreDataMessageID: NSManagedObjectID

    /**
     The email of the account this message belongs to, in case the folder and account
     are not yet setup.
     */
    let accountEmail: String

    /**
     Message to encrypt is meant for sending?
     */
    let outgoing: Bool

    /**
     After encryption has happened, all mails supposed to be sent are stored here.
     This may include both encrypted and unencrypted messages, and should have a count > 0.
     Those mails can then be sent with `SendMailOperation`.
     When `SendMailOperation` executes, mails will move from `mailsToSend` to `mailsSent`.
     */
    public var mailsToSend: [PEPMail] = []

    /**
     After the `SendMailOperation` has done its job, all sent mails should be noted here.
     */
    public var mailsSent: [PEPMail] = []

    public init(connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil,
                coreDataMessageID: NSManagedObjectID, accountEmail: String,
                outgoing: Bool = true) {
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
        self.coreDataMessageID = coreDataMessageID
        self.accountEmail = accountEmail
        self.outgoing = outgoing
    }
}
