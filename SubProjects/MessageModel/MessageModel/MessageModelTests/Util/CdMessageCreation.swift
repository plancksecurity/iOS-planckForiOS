//
//  CdMessageCreation.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 23.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS
@testable import MessageModel

class CdMessageCreation {
    /// Creates the most basic and valid message that matches most criterias for getting appended.
    static func validCdMessageAndAccount(
        context: NSManagedObjectContext) -> (CdMessage, CdAccount) {
        // Create the minimally possible version of a message.
        let cdIdent = CdIdentity(context: context)
        cdIdent.address = "some_address@example.com"

        let cdAcc = CdAccount(context: context)
        cdAcc.identity = cdIdent

        let cdFolder = CdFolder(context: context)
        cdFolder.name = "outbox"
        // Mark messages in that folder as "to be appended".
        cdFolder.folderType = FolderType.typesSyncedWithImapServer[0]
        cdFolder.account = cdAcc

        let cdMsg = CdMessage(context: context)
        cdMsg.pEpProtected = false
        cdMsg.pEpRating = Int16(PEPRating.undefined.rawValue)
        cdMsg.uid = 0 // Would normally be appended.
        cdMsg.uuid = "0000000001"
        cdMsg.bcc = NSOrderedSet()
        cdMsg.cc = NSOrderedSet()
        cdMsg.optionalFields = NSOrderedSet()
        cdMsg.references = NSOrderedSet()
        cdMsg.parent = cdFolder
        context.saveAndLogErrors()

        return (cdMsg, cdAcc)
    }
}
