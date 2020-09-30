//
//  CdMessage+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 04.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PEPObjCAdapterFramework
import pEpIOSToolbox

extension CdMessage {

    /// Updates the message to the given color rating.
    func update(rating: PEPRating) {
        self.pEpRating = Int16(rating.rawValue)
    }

    /**
     Updates all properties from the given `PEPMessage`.
     Used after a message has been decrypted.
     */
    func update(pEpMessage: PEPMessage,
                rating: PEPRating? = nil,
                context: NSManagedObjectContext) {
        if let theRating = rating {
            update(rating: theRating)
        }
        shortMessage = pEpMessage.shortMessage?.applyingDos2Unix()
        longMessage = pEpMessage.longMessage?.applyingDos2Unix()
        longMessageFormatted = pEpMessage.longMessageFormatted?.applyingDos2Unix()

        if let saveSent = pEpMessage.sentDate {
            sent = saveSent
        }

        if let safeReceived = pEpMessage.receivedDate {
            received = safeReceived
        }

        uuid = pEpMessage.messageID

        let refsToConvert = MutableOrderedSet<String>()
        if let refs = pEpMessage.references {
            for item in refs {
                refsToConvert.append(item)
            }
        }

        if let refs2 = pEpMessage.inReplyTo{
            for item in refs2 {
                refsToConvert.append(item)
            }
        }
        self.replace(referenceStrings: Array(refsToConvert), context: context)

        var attachments = [CdAttachment]()
        if let origAttachments = pEpMessage.attachments {
            for pEpAttachment in origAttachments {
                let attach = CdAttachment(context: context)
                attach.data = pEpAttachment.data
                attach.mimeType = pEpAttachment.mimeType?.lowercased()
                attach.fileName = pEpAttachment.filename
                attach.contentDispositionTypeRawValue = Int16(pEpAttachment.contentDisposition.rawValue)
                attachments.append(attach)
            }
        }

        self.attachments = NSOrderedSet(array: attachments)
        CdAttachment.deleteOrphans(context: context)

        var newOptFields = [CdHeaderField]()
        if let optFields = pEpMessage.optionalFields {
            for headerfield in optFields {
                let cdHeaderField = CdHeaderField(context: context)
                cdHeaderField.name = headerfield[0]
                cdHeaderField.value = headerfield[1]
                cdHeaderField.message = self
                newOptFields.append(cdHeaderField)
            }
        }

        optionalFields = NSOrderedSet(array: newOptFields)

        CdHeaderField.deleteOrphans(context: context)

        from = CdIdentity.from(pEpContact: pEpMessage.from, context: context)

        to = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage.to, context: context))
        cc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage.cc, context: context))
        bcc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage.bcc, context: context))

        replyTo = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage.replyTo,
                                                      context: context))
    }

    func updateKeyList(keys: [String], context: NSManagedObjectContext) {
        if !keys.isEmpty {
            self.keysFromDecryption = NSOrderedSet(array: keys.map {
                return CdKey.create(stringKey: $0, context: context)
            })
        } else {
            self.keysFromDecryption = nil
        }
    }

    /// Converts a core data message into the format required by pEp.
    /// - Returns: A PEPMessage suitable for processing with pEp.
    func pEpMessage() -> PEPMessage {
        let outgoingFolderTypes = [FolderType.sent, .drafts, .outbox]
        let isOutgoing = outgoingFolderTypes.contains(parent?.folderType ?? FolderType.normal)
        let pEpMessage = PEPMessage()

        pEpMessage.sentDate = sent
        pEpMessage.shortMessage = shortMessage
        pEpMessage.longMessage = longMessage
        pEpMessage.longMessageFormatted = longMessageFormatted

        pEpMessage.to = CdIdentity.pEpIdentities(cdIdentitiesSet: to)
        pEpMessage.cc = CdIdentity.pEpIdentities(cdIdentitiesSet: cc)
        pEpMessage.bcc = CdIdentity.pEpIdentities(cdIdentitiesSet: bcc)

        pEpMessage.from = from?.pEpIdentity()
        pEpMessage.messageID = uuid
        pEpMessage.direction = isOutgoing ? .outgoing : .incoming

        if let cdAttachments = attachments?.array as? [CdAttachment] {
            pEpMessage.attachments = cdAttachments.map {
                return $0.pEpAttachment
            }
        }

        let refStrings = extractReferenceStrings(referenceType: .reference)
        if !refStrings.isEmpty {
            pEpMessage.references = refStrings
        }

        let inReplyToStrings = extractReferenceStrings(referenceType: .inReplyTo)
        if !inReplyToStrings.isEmpty {
            pEpMessage.inReplyTo = inReplyToStrings
        }

        var replyTos = [PEPIdentity]()
        if let r = replyTo {
            for ident in r.array {
                if let cdIdent = ident as? CdIdentity {
                    replyTos.append(cdIdent.pEpIdentity())
                }
            }
            if !replyTos.isEmpty {
                pEpMessage.replyTo = replyTos
            }
        }

        if let headerFields = optionalFields?.array as? [CdHeaderField] {
            var theFields = [(String, String)]()
            for field in headerFields {
                if let name = field.name, let value = field.value {
                    theFields.append((name, value))
                }
            }
            if !theFields.isEmpty {
                pEpMessage.optionalFields = theFields.map { (s1, s2) in
                    return [s1, s2]
                }
            }
        }

        if pEpMessage.direction == .incoming {
            guard let pEpIdentityReceiver = parent?.account?.identity?.pEpIdentity() else {
                Log.shared.errorAndCrash("An incomming message MUST be received by someone. Invalid state!")
                return pEpMessage
            }
            pEpMessage.receivedBy = pEpIdentityReceiver
        }

        return pEpMessage
    }

    static func allMessagesMarkedForAppend(inAccount account: CdAccount,
                                           context: NSManagedObjectContext) -> [CdMessage] {
        let p = CdMessage.PredicateFactory.needImapAppend(
            inAccountWithAddress: account.identityOrCrash.addressOrCrash)
        let cdMessages = CdMessage.all(predicate: p, in: context) as? [CdMessage] ?? []
        return cdMessages
    }

    func outgoingMessageRating(completion: @escaping (PEPRating)->Void) {
        if !pEpProtected {
            completion(.unencrypted)
            return
        }
        
        PEPAsyncSession().outgoingRating(for: pEpMessage(), errorCallback: { (_) in
            completion(.undefined)
        }) { (rating) in
            completion(rating)
        }
    }

    func setOriginalRatingHeader(rating: PEPRating) {
        guard let moc = managedObjectContext else {
            Log.shared.errorAndCrash("The object we are working on has been deleted from MOC.")
            return
        }

        // Find existing field for key ...
        let existingForKey =
            optionalFields?.filter { ($0 as! CdHeaderField).name == Headers.originalRating.rawValue } ?? []
        if existingForKey.count > 1 {
            // ... assure we have max one ...
            Log.shared.errorAndCrash("Invalid state. More than one field for key %@",
                                     Headers.originalRating.rawValue)
        }
        if let existing = existingForKey.first as? CdHeaderField {
            // ... and delete it.
            moc.delete(existing)
        }
        let headerField = CdHeaderField(context: moc)
        headerField.name = Headers.originalRating.rawValue
        headerField.value = rating.asString()

        addToOptionalFields(headerField)
    }

    // TODO: This is duplicated between MM and Cd.
    var isOnTrustedServer: Bool {
        guard let imapServer = parent?.account?.server(with: .imap) else {
            // Some tests seem to think that this is a valid case. Don't crash.
            return false
        }
        let accountHasBeenCreatedInLocalNetwork = imapServer.automaticallyTrusted
        let userDecidedToTrustServer = imapServer.manuallyTrusted
        return accountHasBeenCreatedInLocalNetwork || userDecidedToTrustServer
    }

    /// - Returns: all messages marked for UidMoveToTrash
    static func allMessagesMarkedForMoveToFolder(inAccount account: CdAccount,
                                                 context: NSManagedObjectContext) -> [CdMessage] {
        let predicateInAccount = CdMessage.PredicateFactory.belongingToAccountWithAddress(
            address: account.identityOrCrash.addressOrCrash
        )
        let predicateMarkedForMove = CdMessage.PredicateFactory.markedForMoveToFolder()
        let isNotFakeMessage = CdMessage.PredicateFactory.isNotFakeMessage()
        let predicates = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateInAccount,
                                                                             predicateMarkedForMove,
                                                                             isNotFakeMessage])
        let cdMessages = CdMessage.all(predicate: predicates, in: context) as? [CdMessage] ?? []
        return cdMessages
    }

    var underAttack: Bool {
        get {
            if let rating = PEPRating(rawValue: Int32(pEpRating)) {
                return rating.isUnderAttack()
            }
            return false
        }
    }
}
