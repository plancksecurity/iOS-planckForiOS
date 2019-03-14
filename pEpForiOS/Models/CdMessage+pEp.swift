
//
//  CdMessage+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdMessage {
    /**
     Updates the message to the given color rating.
     */
    public func update(rating: PEP_rating) {
        self.pEpRating = Int16(rating.rawValue)
    }

    /**
     Updates all properties from the given `PEPMessage`.
     Used after a message has been decrypted.
     */
    public func update(pEpMessageDict: PEPMessageDict, rating: PEP_rating? = nil) {
        if let theRating = rating {
            update(rating: theRating)
        }

        shortMessage = (pEpMessageDict[kPepShortMessage] as? String)?.applyingDos2Unix()
        longMessage = (pEpMessageDict[kPepLongMessage] as? String)?.applyingDos2Unix()
        longMessageFormatted = (pEpMessageDict[kPepLongMessageFormatted]
            as? String)?.applyingDos2Unix()

        if let testsent = pEpMessageDict[kPepSent] as? Date {
            sent = testsent
        }
        if let testrecived = pEpMessageDict[kPepReceived] as? Date {
            received = testrecived
        }

        uuid = pEpMessageDict[kPepID] as? String

        let refsToConvert = MutableOrderedSet<String>()
        if let refs = pEpMessageDict[kPepReferences] as? [String] {
            for item in refs {
                refsToConvert.append(item)
            }
        }

        if let refs2 = pEpMessageDict[kPepInReplyTo] as? [String] {
            for item in refs2 {
                refsToConvert.insert(item)
            }
        }
        self.replace(referenceStrings: refsToConvert.array)

        var attachments = [CdAttachment]()
        if let attachmentObjects = pEpMessageDict[kPepAttachments] as? NSArray {
            for atDict in attachmentObjects {
                guard let at = atDict as? PEPAttachment else {
                    continue
                }
                let attach = CdAttachment.create()
                attach.data = at.data
                attach.length = Int64(at.data.count)
                attach.mimeType = at.mimeType?.lowercased()
                attach.fileName = at.filename
                attach.contentDispositionTypeRawValue = Int16(at.contentDisposition.rawValue)
                attachments.append(attach)
            }
        }

        self.attachments = NSOrderedSet(array: attachments)
        CdAttachment.deleteOrphans()

        var newOptFields = [CdHeaderField]()
        if let optFields = pEpMessageDict[kPepOptFields] as? NSArray {
            for item in optFields {
                if let headerfield = item as? NSArray {
                    let cdHeaderField = CdHeaderField.create()
                    cdHeaderField.name = headerfield[0] as? String
                    cdHeaderField.value = headerfield[1] as? String
                    cdHeaderField.message = self
                    newOptFields.append(cdHeaderField)
                }
            }
        }

        if !newOptFields.isEmpty {
            optionalFields = NSOrderedSet(array: newOptFields)
        } else {
            optionalFields = nil
        }
        CdHeaderField.deleteOrphans()

        from = CdIdentity.from(pEpContact: pEpMessageDict[kPepFrom] as? PEPIdentity)
        to = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessageDict[kPepTo] as? [PEPIdentity]))
        cc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessageDict[kPepCC] as? [PEPIdentity]))
        bcc = NSOrderedSet(array: CdIdentity.from(
            pEpContacts: pEpMessageDict[kPepBCC] as? [PEPIdentity]))
        replyTo = NSOrderedSet(array: CdIdentity.from(
            pEpContacts: pEpMessageDict[kPepReplyTo] as? [PEPIdentity]))
    }

    public func updateKeyList(keys: [String]) {
        if !keys.isEmpty {
            self.keysFromDecryption = NSOrderedSet(array: keys.map {
                return CdKey.create(stringKey: $0)
            })
        } else {
            self.keysFromDecryption = nil
        }
    }

    public func pEpMessageDict(outgoing: Bool = true) -> PEPMessageDict {
        return PEPUtil.pEpDict(cdMessage: self, outgoing: outgoing)
    }

    public func pEpMessage(outgoing: Bool = true) -> PEPMessage {
        return PEPUtil.pEp(cdMessage: self, outgoing: outgoing)
    }

    public func isProbablyPGPMime() -> Bool {
        return PEPUtil.isProbablyPGPMime(cdMessage: self)
    }
}
