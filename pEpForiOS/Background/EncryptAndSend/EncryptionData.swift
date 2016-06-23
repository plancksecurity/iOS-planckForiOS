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
class EncryptionData {
    /**
     Needed for accessing core data in the background.
     */
    let coreDataUtil: ICoreDataUtil

    /**
     The original unencrypted message ID. Needed as an object ID so it can be passed
     between operations.
     */
    let messageID: NSManagedObjectID

    /**
     The email of the account this message belongs to, in case the folder and account
     are not yet setup.
     */
    let accountEmail: String

    init(coreDataUtil: ICoreDataUtil, messageID: NSManagedObjectID, accountEmail: String) {
        self.coreDataUtil = coreDataUtil
        self.messageID = messageID
        self.accountEmail = accountEmail
    }
}
