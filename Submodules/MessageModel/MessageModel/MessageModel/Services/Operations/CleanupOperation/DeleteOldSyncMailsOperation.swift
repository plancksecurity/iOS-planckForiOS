//
//  DeleteOldSyncMailsOperation.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 17.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

/// Removes (mark as deleted in IMAP terms) old autoconsumable messages.
///
/// Messages to be deleted must have the following characteristics:
/// * older than a certain threshold
/// * not yet marked as IMAP-delete
/// * in the inbox OR pEpFolder
/// * contain certain headers that mark them as "auto-consumable"
class DeleteOldSyncMailsOperation: ConcurrentBaseOperation {
    open override func main() {
        privateMOC.perform { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            let p1 = CdMessage.PredicateFactory.sentDateOlderThanNeededForAutoConsume()
            let p2 = CdMessage.PredicateFactory.isAutoConsumable()
            let p3 = CdMessage.PredicateFactory.notImapFlagDeleted()

            let pFolder1 = CdMessage.PredicateFactory.isInInbox()
            let pFolder2 = CdMessage.PredicateFactory.isInSyncFolder()
            let pFolder = NSCompoundPredicate(orPredicateWithSubpredicates: [pFolder1, pFolder2])

            let p = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3, pFolder])
            let cdMsgs = CdMessage.all(predicate: p, in: me.privateMOC) as? [CdMessage] ?? []
            cdMsgs.forEach() { cdMsg in
                cdMsg.imapMarkDeleted()
            }
            me.privateMOC.saveAndLogErrors()
            me.markAsFinished()
        }
    }
}
