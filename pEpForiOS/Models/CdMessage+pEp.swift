
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
     Updates all properties from the given `PEPMessage`.
     Used after a message has been decrypted.
     */
    public func update(pEpMessage: PEPMessage, pepColorRating: PEP_rating? = nil) {
        if let color = pepColorRating {
            pEpRating = Int16(color.rawValue)
        }

        bodyFetched = true

        shortMessage = pEpMessage[kPepShortMessage] as? String
        longMessage = pEpMessage[kPepLongMessage] as? String
        longMessageFormatted = pEpMessage[kPepLongMessageFormatted] as? String

        if let testsent = pEpMessage[kPepSent] as? NSDate {
            sent = testsent
        }
        if let testrecived = pEpMessage[kPepReceived] as? NSDate {
            received = testrecived
        }

        uuid = pEpMessage[kPepID] as? String

        Log.info(component: #function, content: "before")
        dumpReferences()
        let refsToConvert = MutableOrderedSet<String>()
        if let refs = pEpMessage[kPepReferences] as? [String] {
            for item in refs {
                refsToConvert.append(item)
            }
        }

        if let refs2 = pEpMessage[kPepInReplyTo] as? [String] {
            for item in refs2 {
                refsToConvert.insert(item)
            }
        }
        self.replace(referenceStrings: refsToConvert.array)
        Log.info(component: #function, content: "after decryption")
        dumpReferences()

        Log.info(component: #function, content: "after deleting orphans")
        dumpReferences()

        var attachments = [CdAttachment]()
        if let attachmentDicts = pEpMessage[kPepAttachments] as? NSArray {
            for atDict in attachmentDicts {
                guard let at = atDict as? NSDictionary else {
                    continue
                }
                guard let data = at[kPepMimeData] as? Data else {
                    continue
                }
                let attach = CdAttachment.create()
                attach.data = data as NSData
                attach.size = Int64(data.count)
                if let mt = at[kPepMimeType] as? String {
                    attach.mimeType = mt
                }
                if let fn = at[kPepMimeFilename] as? String {
                    attach.fileName = fn
                }
                attachments.append(attach)
            }
        }

        self.attachments = NSOrderedSet(array: attachments)
        CdAttachment.deleteOrphans()

        var optfield = [CdHeaderField]()
        if let optFieldDict = pEpMessage[kPepOptFields] as? NSArray {
            for item in optFieldDict {
                if let headerfield = item as? NSArray {
                    let cdHeaderField = CdHeaderField.create()
                    cdHeaderField.name = headerfield[0] as? String
                    cdHeaderField.value = headerfield[1] as? String
                    optfield.append(cdHeaderField)
                }
            }
        }

        self.optionalFields = NSOrderedSet(array: optfield)
        CdHeaderField.deleteOrphans()

        from = CdIdentity.from(pEpContact: pEpMessage[kPepFrom] as? PEPIdentity)
        to = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage[kPepTo] as? [PEPIdentity]))
        cc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage[kPepCC] as? [PEPIdentity]))
        bcc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage[kPepBCC] as? [PEPIdentity]))
        replyTo = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage[kPepReplyTo] as? [PEPIdentity]))
    }

    public func pEpMessage(outgoing: Bool = true) -> PEPMessage {
        return PEPUtil.pEp(cdMessage: self, outgoing: outgoing)
    }

    public func isProbablyPGPMime() -> Bool {
        return PEPUtil.isProbablyPGPMime(cdMessage: self)
    }

    /**
     Message has just been decrypted, so present it to the UI as new.
     */
    public func updateDecrypted() {
        if let msg = message() {
            MessageModelConfig.messageFolderDelegate?.didChange(messageFolder: msg)
        }
    }
}
