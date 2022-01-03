//
//  CdMessage+PredicateFactory.swift
//  MessageModel
//
//  Created by Andreas Buff on 12.02.18.
//  Copyright © 2018 pEp Security S.A. All rights reserved.
//

import CoreData
import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

extension CdMessage {

    struct PredicateFactory {
        //MB:-
//        static func inUnifiedFolder() -> NSPredicate {
//            return NSPredicate(format: "%K = true", RelationshipKeyPath.cdMessage_parent_account_isUnifiable)
//        }

        /// - Returns: Predicate to fetch all messages that need to be IMAP appended (uploaded to server).
        static func notWaitingForImapAppend() -> NSPredicate {
            return NSPredicate(format: "%K != 0", CdMessage.AttributeName.uid)
        }

        static func notImapFlagDeleted() -> NSPredicate {
            var predicates = [NSPredicate]()
            predicates.append(NSPredicate(format: "%K = nil", CdMessage.RelationshipName.imap))
            predicates.append(NSPredicate(format: "%K = nil",
                                    RelationshipKeyPath.cdMessage_imap_localFlags))
            predicates.append(NSPredicate(format: "%K = false",
                                    RelationshipKeyPath.cdMessage_imap_localFlags + "." +
                                    CdImapFlags.AttributeName.flagDeleted))
            return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }

        static func decrypted() -> NSPredicate {
            return NSPredicate(format: "%K != %d",
                               CdMessage.AttributeName.pEpRating, PEPRating.undefined.rawValue)
        }

        static func notMarkedForMoveToFolder() -> NSPredicate {
            var predicates = [NSPredicate]()
            predicates.append(NSPredicate(format: "%K = nil",
                                          CdMessage.RelationshipName.targetFolder))
            predicates.append(NSPredicate(format: "%K = %K",
                                          CdMessage.RelationshipName.targetFolder,
                                          CdMessage.RelationshipName.parent))
            return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }

        /// Predicate to fetch CdMessages that belong to a given account
        ///
        /// - Parameter cdAccount: account found messages belong to
        /// - Returns: predicate for messages that belong to the given account
        static func belongingToAccount(cdAccount: CdAccount) -> NSPredicate {
            return NSPredicate(format: "%K = %@",
                                    RelationshipKeyPath.cdMessage_parent_account, cdAccount)
        }

        /// Predicate to fetch CdMessages that belong to a given account
        ///
        /// - Parameter address: address of the user or the acccount
        /// - Returns: predicate for messages that belong to the given account
        static func belongingToAccountWithAddress(address:String) -> NSPredicate {
            return NSPredicate(format: "%K like[c] %@",
                                    RelationshipKeyPath.cdMessage_parent_account + "." +
                                    RelationshipKeyPath.cdAccount_identity_address, address)
        }

        /// Predicate to fetch CdMessages that belong to a folder with given name
        ///
        /// - Parameter parentFolderName: name of parentfolder
        /// - Returns: predicate for messages that belong to a folder with given name
        static func belongingToParentFolderNamed(parentFolderName:String) -> NSPredicate {
            return NSPredicate(format: "%K = %@",
                                    RelationshipKeyPath.cdMessage_parent_name, parentFolderName)
        }

        /// Predicate to fetch CdMessages that belong to a folder
        ///
        /// - Parameter folder: parent folder
        /// - Returns: predicate for messages that belong to a folder
        static func belongingToParentFolder(parentFolder: CdFolder) -> NSPredicate {
            return NSPredicate(format: "%K = %@", CdFolder.RelationshipName.parent, parentFolder)
        }

        static func allMessagesBetweenUids(firstUid: UInt,
                                           lastUid: UInt) -> NSPredicate {
            return NSPredicate(format: "%K >= %d and %K <= %d",
                               CdMessage.AttributeName.uid, firstUid,
                               CdMessage.AttributeName.uid, lastUid)
        }

        static func parentFolder(_ parent: CdFolder,
                                 uid: UInt) -> NSPredicate {
            return NSPredicate(format: "parent = %@ and uid = %d",
                               parent,
                               uid)
        }

        static func flagged(value: Bool) -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                                    RelationshipKeyPath.cdMessage_imap_localFlags + "." +
                                    CdImapFlags.AttributeName.flagFlagged, value)
        }

        static func unread(value: Bool) -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                                    RelationshipKeyPath.cdMessage_imap_localFlags + "." +
                                    CdImapFlags.AttributeName.flagSeen, !value)
        }

        static func messageContains(value: String) -> NSPredicate {
            var orPredicates = [NSPredicate]()
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            CdMessage.AttributeName.shortMessage, value))
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            CdMessage.AttributeName.longMessage, value))
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            CdMessage.AttributeName.longMessageFormatted, value))
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            RelationshipKeyPath.cdMessage_from_address, value))
            orPredicates.append(NSPredicate(format: "%K CONTAINS[C] %@",
                                            RelationshipKeyPath.cdMessage_from_userName, value))

            return NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates)
        }

        static func existingMessages() -> NSPredicate {
            var predicates = [NSPredicate]()
            predicates.append(notWaitingForImapAppend())
            predicates.append(notImapFlagDeleted())
            predicates.append(notMarkedForMoveToFolder())
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        /// Returns a Predicate to filter based on the folder type passed by parameter.
        /// - Parameter folderType: The folder type to filter
        /// - Returns: The predicate to query.
        static func isIn(folderOfType: FolderType) -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                               RelationshipKeyPath.cdMessage_parent_typeRawValue,
                               folderOfType.rawValue)
        }

        static func isInInbox() -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                               RelationshipKeyPath.cdMessage_parent_typeRawValue,
                               FolderType.inbox.rawValue)
        }

        static func isInSyncFolder() -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                               RelationshipKeyPath.cdMessage_parent_typeRawValue,
                               FolderType.pEpSync.rawValue)
        }

        static func hasViewableAttachments() -> NSPredicate {
            let dontShowRatingsRawValues = PEPRating.neverShowAttachmentsForRatings
                .map { $0.rawValue }
            let notUnencryptable = NSPredicate(format: "NOT (%K IN %@)",
                                               CdMessage.AttributeName.pEpRating,
                                               dontShowRatingsRawValues)
            let viewableOnly = NSPredicate(
                format: "(SUBQUERY(%K, $a, (not ($a.%K in %@)))).@count > 0",
                CdMessage.RelationshipName.attachments,
                CdAttachment.AttributeName.mimeType,
                MimeTypeUtils.unviewableMimeTypes)
            return NSCompoundPredicate(andPredicateWithSubpredicates: [notUnencryptable, viewableOnly])
        }

        static func processed() -> NSPredicate {
            return NSPredicate(format: "%K != %d",
                               CdMessage.AttributeName.pEpRating,
                               Int(PEPRating.undefined.rawValue))
        }

        static func needsDecrypt() -> NSPredicate {
            let pMarkedForDecrypt = NSPredicate(format: "%K = true",
                                                CdMessage.AttributeName.needsDecrypt)
            let predicateIsFromServer = NSPredicate(format: "%K > 0", CdMessage.AttributeName.uid)
            let predicates = [CdMessage.PredicateFactory.existingMessages(),
                              pMarkedForDecrypt,
                              predicateIsFromServer]
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        static func undecryptable() -> NSPredicate {
            let rawUndecryptableRatings = PEPRating.undecryptableRatings.map { $0.rawValue }
            return NSPredicate(format: "%K IN %@",
                               CdMessage.AttributeName.pEpRating,
                               rawUndecryptableRatings)
        }

        /**
         - Note: \Recent is never taken into consideration, since it always is set from the server,
         but never overridden in the client.
         - Returns: A predicate that will search for all messages in a given folder whose flags
         should be synced back to the server. That is, messages with locally changed flags.
         */
        static func changedFlags(folder: CdFolder? = nil) -> NSPredicate {
            var predicates = [NSPredicate]()
            if let f = folder {
                predicates.append(NSPredicate(format: "%K = %@", CdMessage.RelationshipName.parent, f))
            }
            var orPredicates = [NSPredicate]()
            orPredicates.append(NSPredicate(format: "%K != %K",
                                            RelationshipKeyPath.cdMessage_imap_localFlags + "." +
                                                CdImapFlags.AttributeName.flagAnswered,
                                            RelationshipKeyPath.cdMessage_imap_serverFlags + "." +
                                                CdImapFlags.AttributeName.flagAnswered))
            orPredicates.append(NSPredicate(format: "%K != %K",
                                            RelationshipKeyPath.cdMessage_imap_localFlags + "." +
                                                CdImapFlags.AttributeName.flagDraft,
                                            RelationshipKeyPath.cdMessage_imap_serverFlags + "." +
                                                CdImapFlags.AttributeName.flagDraft))
            orPredicates.append(NSPredicate(format: "%K != %K",
                                            RelationshipKeyPath.cdMessage_imap_localFlags + "." +
                                                CdImapFlags.AttributeName.flagFlagged,
                                            RelationshipKeyPath.cdMessage_imap_serverFlags + "." +
                                                CdImapFlags.AttributeName.flagFlagged))
            orPredicates.append(NSPredicate(format: "%K != %K",
                                            RelationshipKeyPath.cdMessage_imap_localFlags + "." +
                                                CdImapFlags.AttributeName.flagSeen,
                                            RelationshipKeyPath.cdMessage_imap_serverFlags + "." +
                                                CdImapFlags.AttributeName.flagSeen))
            orPredicates.append(NSPredicate(format: "%K != %K",
                                            RelationshipKeyPath.cdMessage_imap_localFlags + "." +
                                                CdImapFlags.AttributeName.flagDeleted,
                                            RelationshipKeyPath.cdMessage_imap_serverFlags + "." +
                                                CdImapFlags.AttributeName.flagDeleted))
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates))
            predicates.append(NSPredicate(format: "%K != %d",
                                          CdMessage.AttributeName.uid, CdMessage.uidNeedsAppend))
            predicates.append(isNotFakeMessage())

            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        /**
         - Returns: The predicate (for CdMessage) to get all messages contained in that folder,
         even the deleted ones, so we don't fetch them again from the server.
         */
        static func allMessagesIncludingDeleted(parentFolder: CdFolder,
                                                fakeMessagesIncluded: Bool = false) -> NSPredicate {

            let inParentFolder = NSPredicate(format: "%K = %@",
                                             CdMessage.RelationshipName.parent,
                                             parentFolder)
            var p = [inParentFolder]
            if !fakeMessagesIncluded {
                let isNotFakeMessage = CdMessage.PredicateFactory.isNotFakeMessage()
                p.append(isNotFakeMessage)
            }

            return NSCompoundPredicate(andPredicateWithSubpredicates: p)
        }

        /**
         - Returns: The predicate (for CdMessage) to get all (undeleted, not marked to move to another folder, valid)
         messages contained in that folder.
         */
        static func allMessages(parentFolder: CdFolder) -> NSPredicate {
            let p1 = CdMessage.PredicateFactory
                .allMessagesIncludingDeleted(parentFolder: parentFolder,
                                             fakeMessagesIncluded: true)
            let p2 = CdMessage.PredicateFactory.notImapFlagDeleted()
            let p3 = CdMessage.PredicateFactory.notMarkedForMoveToFolder()
            return NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])
        }

        static func allMessagesExistingOnServer(parentFolder: CdFolder) -> NSPredicate {
            let p1 = CdMessage.PredicateFactory.allMessagesIncludingDeleted(parentFolder: parentFolder)
            let p2 = NSPredicate(format: "%K != %d",
                                 CdMessage.AttributeName.uid,
                                 CdMessage.uidNeedsAppend)
            return NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        }
    }
}
