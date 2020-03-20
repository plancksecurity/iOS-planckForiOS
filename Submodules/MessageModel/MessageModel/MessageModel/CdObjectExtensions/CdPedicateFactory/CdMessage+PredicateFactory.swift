//
//  CdMessage+PredicateFactory.swift
//  MessageModel
//
//  Created by Andreas Buff on 12.02.18.
//  Copyright © 2018 pEp Security S.A. All rights reserved.
//

import CoreData
import PEPObjCAdapterFramework

extension CdMessage {

    struct PredicateFactory {

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

        static func unprocessed() -> NSPredicate {
            return NSPredicate(format: "%K = %d",
                               CdMessage.AttributeName.pEpRating,
                               Int(PEPRating.undefined.rawValue))
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
    }
}
