//
//  CdMessagePredicateFactory+Imap.swift
//  pEp
//
//  Created by Andreas Buff on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Predicates MessageModel should not be aware of
extension CdMessage.PredicateFactory {

    /// Predicate to fetch all CdMessages that need to be moved to another folder.
    ///
    /// - Returns: Predicate for CdMessages that need to be moved to another folder.
    static public func markedForMoveToFolder() -> NSPredicate {
        return NSPredicate(format: "targetFolder != nil AND targetFolder != parent")
    }

//    static public func notMarkedForMoveToFolder() -> NSPredicate {
//        var predicates = [NSPredicate]()
//        predicates.append(NSPredicate(format: "targetFolder == nil"))
//        predicates.append(NSPredicate(format: "targetFolder == parent"))
//        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
//    }

//    static public func unread() -> NSPredicate {
//        return NSPredicate(format: "imap.localFlags.flagSeen = false")
//    }

    /// - Returns: Predicate to fetch all messages that need to be IMAP appended (uploaded to server).
    static public func needImapAppend() -> NSPredicate {
        return NSPredicate(format: "uid = 0 and parent.folderTypeRawValue IN %@",
                           FolderType.typesSyncedWithImapServerRawValues)
    }

    /// Predicate to fetch all messages in a given account that need to be IMAP appended.
    ///
    /// - Parameters:
    ///   - address: address of account to fetch messages for
    /// - Returns: Predicate to fetch all messages in the given folder that need to be IMAP appended.
    static public func needImapAppend(inAccountWithAddress address: String) -> NSPredicate {
        let needAppend = needImapAppend()
        let inAccount = belongingToAccountWithAddress(address: address)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [needAppend, inAccount])
    }

    /// Predicate to fetch all messages in the given folder of a given account that need to be
    /// IMAP appended.
    ///
    /// - Parameters:
    ///   - folderName: name of folder to fetch messages for
    ///   - address: address of account to fetch messages for
    /// - Returns: Predicate to fetch all messages in the given folder that need to be IMAP appended.
    static public func needImapAppend(inFolderNamed folderName: String,
                                      inAccountWithAddress address: String) -> NSPredicate {
        let needAppend = needImapAppend(inAccountWithAddress: address)
        let inFolder = belongingToParentFolderNamed(parentFolderName: folderName)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [needAppend, inFolder])
    }
}
