//
//  CdMessage+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

extension CdMessage {

    //!!!: cleanup
//    public static func create(messageID: String, uid: Int,
//                              parent: CdFolder? = nil) -> CdMessage {
//        let msg = CdMessage.create()
//        msg.uuid = messageID
//        msg.uid = Int32(uid)
//        msg.parent = parent
//        msg.imap = CdImapFields.create()
//        return msg
//    }

    @discardableResult public static func create(withContentOf msg: Message) -> CdMessage? {
        guard let moc = msg.cdObject.managedObjectContext else { //!!!: beware! Context!
            Log.shared.errorAndCrash("no moc")
            return nil
        }
        let cdObjc = msg.cdObject
        let createe = CdMessage(context: moc)
        createe.uid = cdObjc.uid
        createe.uuid = cdObjc.uuid
        createe.parent = cdObjc.parent

        createe.imap = CdImapFields(context: moc)
        createe.assureImapAndFlagsNotNil()

        createe.imap?.localFlags?.flagAnswered = msg.imapFlags.answered
        createe.imap?.localFlags?.flagDeleted = msg.imapFlags.deleted
        createe.imap?.localFlags?.flagDraft = msg.imapFlags.draft
        createe.imap?.localFlags?.flagFlagged = msg.imapFlags.flagged
        createe.imap?.localFlags?.flagRecent = msg.imapFlags.recent
        createe.imap?.localFlags?.flagSeen = msg.imapFlags.seen

        createe.shortMessage = msg.shortMessage
        createe.longMessage = msg.longMessage
        createe.longMessageFormatted = msg.longMessageFormatted

        let cdAttachments = msg.attachments.map { $0.cdObject }
        createe.attachments = NSOrderedSet(array: cdAttachments)

        createe.sent = cdObjc.sent
        createe.received = cdObjc.received
        createe.from = cdObjc.from
        createe.to = cdObjc.to
        createe.cc = cdObjc.cc
        createe.bcc = cdObjc.bcc

        createe.receivedBy = cdObjc.receivedBy

        createe.replyTo = cdObjc.replyTo

        createe.replace(referenceStrings: (cdObjc.references?.compactMap { ($0 as? CdMessageReference)?.reference }) ?? [],
                        context: moc)
        createe.keywords = cdObjc.keywords
        createe.comments = cdObjc.comments

        createe.pEpRating = cdObjc.pEpRating

        createe.keysFromDecryption = cdObjc.keysFromDecryption

        return createe
    }

    func insertAttachment(contentType: String?,
                          filename: String?,
                          contentID: String?,
                          data: Data,
                          contentDispositionRawValue: Int16) {
        guard let moc = managedObjectContext else {
            Log.shared.errorAndCrash("No moc")
            return
        }
        let createe = CdAttachment(context: moc)
        createe.data = data
        createe.mimeType = contentType?.lowercased()
        // We mimic the Engines behaviour to set filename *or* CID in field `filename`. CID has higher prio.
        if let cid = contentID {
            createe.fileName = Attachment.contentIdUrlScheme + "://" + cid
        } else {
            createe.fileName = filename
        }
        createe.contentDispositionTypeRawValue = contentDispositionRawValue

        addToAttachments(createe)
    }
}
