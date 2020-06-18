//
//  CdAccount+TestUtils.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 29.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel
import CoreData
import pEpIOSToolbox

extension CdAccount {
    /**
     - Note: The test for the `sendFrom` identity is very strict and will fail
     in cases like "two identities that 'only' differ in their username".
     */
    public func allMessages(inFolderOfType type: FolderType,
                            sendFrom from: CdIdentity? = nil) -> [CdMessage] {
        guard let moc = from?.managedObjectContext else {
            Log.shared.errorAndCrash("No MOC")
            return []
        }
        var predicates = [NSPredicate]()
        let pIsInAccount = NSPredicate(format: "parent.%@ = %@",
                                     CdFolder.RelationshipName.account, self)
        predicates.append(pIsInAccount)
        let pIsInFolderOfType = NSPredicate(format: "parent.%@ == %d",
                                CdFolder.AttributeName.folderTypeRawValue, type.rawValue)
        predicates.append(pIsInFolderOfType)
        if let from = from {
            let pSenderIdentity = NSPredicate(format: "%K = %@",
                                              CdMessage.RelationshipName.from, from)
            predicates.append(pSenderIdentity)
        }
        let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        guard
            let messages = CdMessage.all(predicate: finalPredicate, in: moc) as? [CdMessage]
            else {
            return []
        }

        return messages
    }
}
