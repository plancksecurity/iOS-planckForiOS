//
//  CdMessage+PEPMessage.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

extension CdMessage {
    enum MessageReferenceType {
        case reference
        case inReplyTo
    }

    /// Adds a message reference to either the message's reference or in-reply-to.
    ///
    /// - Parameters:
    ///   - messageID: The message reference.
    ///   - referenceType: Can be a normal reference, or in-reply-to.
    ///   - context: The managed object context to use.
    /// - Returns: The newly added message reference, in case it's needed.
    func addMessageReference(messageID: String,
                             referenceType: MessageReferenceType,
                             context: NSManagedObjectContext) -> CdMessageReference {

        let predicate = CdMessageReference.PredicateFactory.with(messageID: messageID)
        let cdRefMaybe = CdMessageReference.first(
            predicate:predicate,
            in: context)
        let cdRef = cdRefMaybe ?? CdMessageReference(context: context)

        if cdRefMaybe == nil {
            cdRef.reference = messageID
        }

        switch referenceType {
        case .reference:
            cdRef.addToMessagesReferencing(self)
            self.addToReferences(cdRef)
        case .inReplyTo:
            cdRef.addToMessagesInReplyTo(self)
            self.addToInReplyTo(cdRef)
        }

        return cdRef
    }

    func extractReferenceStrings(referenceType: MessageReferenceType) -> [String] {
        var messageReferences: NSOrderedSet? = nil
        switch referenceType {
        case .reference: messageReferences = self.references
        case .inReplyTo: messageReferences = self.inReplyTo
        }

        let refArray = messageReferences?.array as? [CdMessageReference] ?? []

        return refArray.compactMap() { return $0.reference }
    }
    
    static func from(pEpMessage: PEPMessage, context: NSManagedObjectContext) -> CdMessage {
        let cdMsg = CdMessage(context: context)

        cdMsg.shortMessage = pEpMessage.shortMessage
        cdMsg.longMessage = pEpMessage.longMessage
        cdMsg.longMessageFormatted = pEpMessage.longMessageFormatted

        cdMsg.uuid = pEpMessage.messageID
        cdMsg.from = CdIdentity.from(pEpContact: pEpMessage.from, context: context)

        cdMsg.receivedBy = CdIdentity.from(pEpContact: pEpMessage.receivedBy, context: context)

        for keyword in (pEpMessage.keywords ?? []) {
            let cdKeyword = CdMessageKeyword(context: context)
            cdKeyword.keyword = keyword
            cdMsg.addToKeywords(cdKeyword)
        }

        for ref in (pEpMessage.references ?? []) {
            let _ = cdMsg.addMessageReference(messageID: ref,
                                              referenceType: .reference,
                                              context: context)
        }

        for inReplyToRef in (pEpMessage.inReplyTo ?? []) {
            let _ = cdMsg.addMessageReference(messageID: inReplyToRef,
                                              referenceType: .inReplyTo,
                                              context: context)
        }

        for optField in (pEpMessage.optionalFields ?? []) {
            if let name = optField[safe: 0], let value = optField[safe: 1] {
                let header = CdHeaderField(context: context)
                header.name = name
                header.value = value
                header.message = cdMsg
                cdMsg.addToOptionalFields(header)
            }
        }

        for replyToIdentity in CdIdentity.from(pEpContacts: pEpMessage.replyTo,
                                               context: context) {
            cdMsg.addToReplyTo(replyToIdentity)
        }

        for toIdentity in CdIdentity.from(pEpContacts: pEpMessage.to, context: context) {
            cdMsg.addToTo(toIdentity)
        }

        for ccIdentity in CdIdentity.from(pEpContacts: pEpMessage.cc, context: context) {
            cdMsg.addToCc(ccIdentity)
        }

        for bccIdentity in CdIdentity.from(pEpContacts: pEpMessage.bcc, context: context) {
            cdMsg.addToCc(bccIdentity)
        }

        for att in (pEpMessage.attachments ?? []) {
            let _ = CdAttachment.from(pEpAttachment: att,
                                      parentMessage: cdMsg,
                                      inContext: context)
        }

        return cdMsg
    }
}
