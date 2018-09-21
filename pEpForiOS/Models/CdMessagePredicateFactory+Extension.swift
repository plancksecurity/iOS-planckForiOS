//
//  CdMessagePredicateFactory+Extension.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 05.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Predicates MessageModel should not be aware of
extension CdMessage.PredicateFactory {

    static public func existingMessages() -> NSPredicate {
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "bodyFetched = true"))
        predicates.append(notImapFlagDeleted())
        predicates.append(notMarkedForMoveToFolder())
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static public func isInInbox() -> NSPredicate {
        return NSPredicate(format: "parent.folderTypeRawValue = %d", FolderType.inbox.rawValue)
    }

    static public func hasViewableAttachments() -> NSPredicate {
        let dontShowRatingsRawValues = PEP_rating.neverShowAttachmentsForRatings
            .map { $0.rawValue }
        let notUnencryptable = NSPredicate(format: "NOT (pEpRating IN %@)",
                                           dontShowRatingsRawValues)
        let viewableOnly = NSPredicate(
            format: "(SUBQUERY(attachments, $a, (not ($a.mimeType in %@)))).@count > 0",
            AttachmentFilter.unviewableMimeTypes)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notUnencryptable, viewableOnly])
    }

    public static func unknownToPep() -> NSPredicate {
        var reDecryptionRatings = PEP_rating.retryDecriptionRatings.map {
            return $0.rawValue
        }
        reDecryptionRatings.append(Int32(PEPUtil.pEpRatingNone))

        let predicateDecrypted = NSPredicate(format: "pEpRating in %@",
                                             reDecryptionRatings)
        let predicateIsFromServer = NSPredicate(format: "uid > 0")
        let predicates = [CdMessage.PredicateFactory.existingMessages(),
                          predicateDecrypted,
                          predicateIsFromServer]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    /**
     - Note: \Recent is never taken into consideration, since it always is set from the server,
     but never overridden in the client.
     - Returns: A predicate that will search for all messages in a given folder whose flags
     should be synced back to the server. That is, messages with locally changed flags.
     */
    public static func changedFlags(folder: CdFolder? = nil) -> NSPredicate {
        var predicates = [NSPredicate]()

        if let f = folder {
            predicates.append(NSPredicate(format: "parent = %@", f))
        }

        let pFlags = NSPredicate(format:
            "(imap.localFlags.flagAnswered != imap.serverFlags.flagAnswered) OR " +
                "(imap.localFlags.flagDraft != imap.serverFlags.flagDraft) OR " +
                "(imap.localFlags.flagFlagged != imap.serverFlags.flagFlagged) OR " +
                "(imap.localFlags.flagSeen != imap.serverFlags.flagSeen) OR " +
            "(imap.localFlags.flagDeleted != imap.serverFlags.flagDeleted)")
        predicates.append(pFlags)

        let pUid = NSPredicate(format: "uid != 0")
        predicates.append(pUid)
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
