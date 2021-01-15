//
//  CdFolder+IMAP.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 02.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData
import pEpIOSToolbox

/// IMAP related methods.
extension CdFolder {
    /// Returns the first message found in this folder, that is marked to move to another folder.
    ///
    /// - Returns: the first message found that has to be moved if any, nil otherwize
    func firstMessageThatHasToBeMoved(context: NSManagedObjectContext) -> CdMessage? {
        let isNotFakeMessage = CdMessage.PredicateFactory.isNotFakeMessage()
        let belongingAccount =
            CdMessage.PredicateFactory.belongingToAccountWithAddress(
                address: accountOrCrash.identityOrCrash.addressOrCrash)
        let parentFolder =
            CdMessage.PredicateFactory.belongingToParentFolderNamed(parentFolderName: nameOrCrash)
        let undeleted = CdMessage.PredicateFactory.notImapFlagDeleted() // This can be a problem when deleting the mail in another MUA. Rm this predicate in case we are running into issues.
        let markedForMoveToFolder = CdMessage.PredicateFactory.markedForMoveToFolder()
        let predicates = [isNotFakeMessage,
                          belongingAccount,
                          parentFolder,
                          markedForMoveToFolder,
                          undeleted]
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return CdMessage.first(predicate: compoundPredicate, in: context)
    }

    /// Whether or not the folder represents a remote folder
    // TODO: This is duplicated between MM and Cd.
    var isSyncedWithServer: Bool {
        return folderType.isSyncedWithServer
    }

    static func allRemoteFolders(inAccount account: CdAccount,
                                        context: NSManagedObjectContext) -> [CdFolder] {
        var result = [CdFolder]()

        let pInAccount = CdFolder.PredicateFactory.inAccount(cdAccount: account)
        let pIsRemote = CdFolder.PredicateFactory.isSyncedWithServer()
        let p = NSCompoundPredicate(andPredicateWithSubpredicates: [pInAccount, pIsRemote])
        guard let cdFolders = CdFolder.all(predicate: p, in: context) as? [CdFolder] else {
            Log.shared.errorAndCrash("Error casting")
            return result
        }
        result = cdFolders.filter { $0.isSyncedWithServer }
        return result
    }

    static func matchUidToMsn(folderID: NSManagedObjectID,
                              uid: UInt,
                              msn: UInt,
                              context: NSManagedObjectContext) {
        guard
            let cdFolder = context.object(with: folderID) as? CdFolder,
            let cdMsg = cdFolder.message(byUID: uid, context: context)
            else {
                // Not being able to find the message by UID is no error.
                // This can happen e.g. on first fetch, when no mail has yet been downloaded.
                return
        }
        guard cdMsg.imapFields(context: context).messageNumber != Int32(msn) else {
            // Nothing to do.
            return
        }
        cdMsg.imapFields(context: context).messageNumber = Int32(msn)
        context.saveAndLogErrors()
    }
}
