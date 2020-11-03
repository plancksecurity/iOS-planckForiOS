//
//  CdMessage+Clone.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension CdMessage {

    func cloneWithZeroUID(context: NSManagedObjectContext) -> CdMessage {
        let m = CdMessage(context: context)

        m.uid = 0
        m.uuid = uuid
        m.comments = comments
        m.longMessage = longMessage
        m.longMessageFormatted = longMessageFormatted
        m.pEpProtected = pEpProtected
        m.pEpRating = pEpRating
        m.received = received
        m.sent = sent
        m.shortMessage = shortMessage

        cloneAttachments(to: m, context: context)

        if let bccs = bcc {
            m.bcc = NSOrderedSet(orderedSet: bccs)
        }

        if let ccs = cc {
            m.cc = NSOrderedSet(orderedSet: ccs)
        }

        m.from = from
        m.imap = imap?.clone(context: context)

        func cloneKeys() {
            var newKeys = [CdKey]()
            keysFromDecryption?.compactMap() { return $0 as? CdKey }.forEach() {
                let at = $0.clone(context: context)
                at.message = m
                newKeys.append(at)
            }
            if !newKeys.isEmpty {
                m.keysFromDecryption = NSOrderedSet(array: newKeys)
            }
        }

        cloneKeys()

        if let theKeywords = keywords {
            m.keywords = NSSet(set: theKeywords)
        }

        func cloneOptionalFields() {
            var theOptionalFields = [CdHeaderField]()
            optionalFields?.compactMap() { return $0 as? CdHeaderField }.forEach() {
                let at = $0.clone(context: context)
                at.message = m
                theOptionalFields.append(at)
            }
            if !theOptionalFields.isEmpty {
                m.optionalFields = NSOrderedSet(array: theOptionalFields)
            }
        }

        cloneOptionalFields()

        m.parent = parent
        m.receivedBy = receivedBy

        if let theRefs = references {
            m.references = NSOrderedSet(orderedSet: theRefs)
        }

        m.replyTo = replyTo
        m.targetFolder = targetFolder
        m.to = to

        return m
    }

    private func cloneAttachments(to message: CdMessage, context: NSManagedObjectContext) {
        var clonedAttachments = [CdAttachment]()
        attachments?.compactMap() { $0 as? CdAttachment }.forEach() {
            let cloneAttachment = $0.clone(context: context)
            cloneAttachment.message = message
            replaceLongMessageFormattedAttachmentCid(originalAttachment: $0,
                                                     clonedAttachment: cloneAttachment)
            clonedAttachments.append(cloneAttachment)
        }
        guard !clonedAttachments.isEmpty else {
            return
        }
        message.attachments = NSOrderedSet(array: clonedAttachments)
    }

    private func replaceLongMessageFormattedAttachmentCid(originalAttachment: CdAttachment,
                                                          clonedAttachment: CdAttachment) {
        guard let originalCid = originalAttachment.fileName?.extractCid() else {
            return
        }
        let clonedCid = clonedAttachment.fileName?.extractCid() ?? ""

        longMessageFormatted = longMessageFormatted?.replacingOccurrences(of: originalCid,
                                                                          with: clonedCid)
    }
}
