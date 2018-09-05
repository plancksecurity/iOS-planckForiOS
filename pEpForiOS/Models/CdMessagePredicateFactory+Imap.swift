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

    static public func existingMessages() -> NSPredicate {
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "bodyFetched = true"))//IOS-1274: rm body fetched field. We always fetch everything.
        predicates.append(undeleted())//IOS-1274: take targetfolder into account (FIXED)
        predicates.append(notMarkedForMoveToFolder())
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    /// Predicate to fetch all CdMessages that need to be moved to another folder.
    ///
    /// - Returns: Predicate for CdMessages that need to be moved to another folder.
    static public func markedForMoveToFolder() -> NSPredicate {
        return NSPredicate(format: "targetFolder != nil AND targetFolder != parent")
    }

    /// - Returns: Predicate to fetch all messages that need to be IMAP appended (uploaded to server).
    static public func needImapAppend() -> NSPredicate {
        return NSPredicate(format: "uid = 0 and parent.folderTypeRawValue IN %@",
                           FolderType.typesSyncedWithImapServerRawValues)
    }

    public static func outgoingMails(in cdAccount: CdAccount) -> NSPredicate {
        return NSPredicate(
            format: "parent.folderTypeRawValue = %d and parent.account = %@",
            FolderType.outbox.rawValue, cdAccount)
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
