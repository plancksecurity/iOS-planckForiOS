//
//  CdMessagePredicateFactory+Imap.swift
//  pEp
//
//  Created by Andreas Buff on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

/// IMAP specific predicates (MessageModel should not be aware of)
extension CdMessage.PredicateFactory {

    /// Predicate to fetch all CdMessages that need to be moved to another folder.
    ///
    /// - Returns: Predicate for CdMessages that need to be moved to another folder.
    static func markedForMoveToFolder() -> NSPredicate {
        return NSPredicate(format: "%K != nil AND %K != %@",
                           CdMessage.RelationshipName.targetFolder,
                           CdMessage.RelationshipName.targetFolder, CdMessage.RelationshipName.parent)
    }

    /// - Returns: Predicate to fetch all messages that need to be IMAP appended (uploaded to server).
    static func needImapAppend() -> NSPredicate {
        // Includes messages of certain folder types with UID = 0.
        return NSPredicate(format: "%K = 0 and %K IN %@",
                                        CdMessage.AttributeName.uid,
                                        RelationshipKeyPath.cdMessage_parent_typeRawValue,
                                        FolderType.typesSyncedWithImapServerRawValues)
    }

    static func outgoingMails(in cdAccount: CdAccount) -> NSPredicate {
        return NSPredicate(format: "%K = %d and %K = %@",
                            RelationshipKeyPath.cdMessage_parent_typeRawValue,
                            FolderType.outbox.rawValue,
                            RelationshipKeyPath.cdMessage_parent_account,
                            cdAccount)
    }

    static func isNotFakeMessage() -> NSPredicate {
        return NSPredicate(format: "%K != %d",
                           CdMessage.AttributeName.uid, CdMessage.uidFakeResponsivenes)
    }

    /// Predicate to fetch all messages in a given account that need to be IMAP appended.
    ///
    /// - Parameters:
    ///   - address: address of account to fetch messages for
    /// - Returns: Predicate to fetch all messages in the given folder that need to be IMAP appended.
    static func needImapAppend(inAccountWithAddress address: String) -> NSPredicate {
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
    static func needImapAppend(inFolderNamed folderName: String,
                               inAccountWithAddress address: String) -> NSPredicate {
        let needAppend = needImapAppend(inAccountWithAddress: address)
        let inFolder = belongingToParentFolderNamed(parentFolderName: folderName)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [needAppend, inFolder])
    }

    static func imapDeletedLocally(cdAccount: CdAccount) -> NSPredicate {
        return NSPredicate(
            format: "%K = %d AND %K = %@",
            RelationshipKeyPath.cdMessage_imap_localFlags_flagDeleted,
            true,
            RelationshipKeyPath.cdMessage_parent_account,
            cdAccount)
    }

    static func imapDeletedOnServer(cdAccount: CdAccount) -> NSPredicate {
        return NSPredicate(
            format: "%K = %d AND %K = %@",
            RelationshipKeyPath.cdMessage_imap_serverFlags_flagDeleted,
            true,
            RelationshipKeyPath.cdMessage_parent_account,
            cdAccount)
    }
}
