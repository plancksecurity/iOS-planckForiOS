//
//  EncryptionData.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 Contains all data that is needed for encrypting and sending messages.
 By sourcing out all needed data, it becomes possible to chain operations, like
 one for encrypting, one for sending the messages (like e-mails),
 and one for persisting the result on the IMAP server.
 */
open class EncryptionData {
    /**
     Needed for accessing core data.
     TODO: Should be removed as soon as all Ops dealing with it have been updated.
     */
    let coreDataUtil: CoreDataUtil = CoreDataUtil()

    /**
     For the save message operation.
     */
    let imapConnectInfo: EmailConnectInfo

    /**
     For the send message operation.
     */
    let smtpConnectInfo: EmailConnectInfo

    /**
     For getting a SMTP connection.
     */
    let connectionManager: ConnectionManager

    /**
     The original unencrypted message ID. Needed as an object ID so it can be passed
     between operations.
     */
    let messageID: NSManagedObjectID

    /**
     Message to encrypt is meant for sending?
     */
    let outgoing: Bool

    /**
     After encryption has happened, all messages supposed to be sent are stored here.
     This may include both encrypted and unencrypted messages, and should have a count > 0.
     Those messages can then be sent with `SendMessageOperation`.
     When `SendMessageOperation` executes, messages will move from `messagesToSend` to 
     `messagesSent`.
     */
    open var messagesToSend: [PEPMessage] = []

    /**
     After encryption, the original mail will be stored here, in encrypted form.
     This is the message that should be stored then in the sent folder.
     */
    open var messageEncryptedForSelf: PEPMessage?

    /**
     After the `SendMailOperation` has done its job, all sent mails should be noted here.
     */
    open var messagesSent: [PEPMessage] = []

    public init(imapConnectInfo: EmailConnectInfo, smtpConnectInfo: EmailConnectInfo,
                connectionManager: ConnectionManager, messageID: NSManagedObjectID,
                outgoing: Bool = true) {
        self.connectionManager = connectionManager
        self.imapConnectInfo = imapConnectInfo
        self.smtpConnectInfo = smtpConnectInfo
        self.messageID = messageID
        self.outgoing = outgoing
    }
}
