//
//  Folder+pEp.swift
//  pEp
//
//  Created by Andreas Buff on 12.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Folder {

    var localizedName: String {
        let validInboxNameVariations = [ImapSync.defaultImapInboxName, "INBOX", "Inbox", "inbox"]

        switch realName {
        case let tmp where  validInboxNameVariations.contains(tmp):
             return NSLocalizedString("Inbox", comment: "Name of INBOX mailbox (of one account)")
        case UnifiedInbox.defaultUnifiedInboxName:
            return NSLocalizedString("All",
                                     comment:
                "Name of unified inbox (showing messages of all accoounts")
        case FolderType.outbox.folderName():
            return NSLocalizedString("Outbox",
                                     comment:
                "Name of outbox (showing messages to send")
        default:
            return realName
        }
    }

    /// Returns the first message found in this folder, that is marked to move to another folder.
    ///
    /// - Returns: the first message found that has to be moved if any, nil otherwize
    public func firstMessageThatHasToBeMoved() -> Message? {
        let isNotFakeMessage = CdMessage.PredicateFactory.isNotFakeMessage()
        let belongingAccount =
            CdMessage.PredicateFactory.belongingToAccountWithAddress(address: account.user.address)
        let parentFolder =
            CdMessage.PredicateFactory.belongingToParentFolderNamed(parentFolderName: name)
        let undeleted = CdMessage.PredicateFactory.notImapFlagDeleted()
        let markedForMoveToFolder = CdMessage.PredicateFactory.markedForMoveToFolder()
        let predicates = [isNotFakeMessage,
                          belongingAccount,
                          parentFolder,
                          markedForMoveToFolder,
                          undeleted]
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let cdMessage = CdMessage.first(predicate: compoundPredicate)

        return cdMessage?.message()
    }
}
