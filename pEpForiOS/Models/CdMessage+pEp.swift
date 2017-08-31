
//
//  CdMessage+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdMessage {

    open var sendStatus: SendStatus {
        get {
            guard let status = SendStatus(rawValue: self.sendStatusRawValue) else {
                Log.shared.errorAndCrash(component: #function, errorString: "No sendStatus?!")
                return SendStatus.none
            }
            return status
        }
        set {
            self.sendStatusRawValue = newValue.rawValue
        }
    }

    /**
     Updates all properties from the given `PEPMessage`.
     Used after a message has been decrypted.
     */
    public func update(pEpMessage: PEPMessage, pEpColorRating: PEP_rating? = nil) {
        if let color = pEpColorRating {
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
                attach.length = Int64(data.count)
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

        var newOptFields = [CdHeaderField]()
        if let optFields = pEpMessage[kPepOptFields] as? NSArray {
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

        self.optionalFields = NSOrderedSet(array: newOptFields)
        CdHeaderField.deleteOrphans()

        from = CdIdentity.from(pEpContact: pEpMessage[kPepFrom] as? PEPIdentity)
        to = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage[kPepTo] as? [PEPIdentity]))
        cc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage[kPepCC] as? [PEPIdentity]))
        bcc = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage[kPepBCC] as? [PEPIdentity]))
        replyTo = NSOrderedSet(array: CdIdentity.from(pEpContacts: pEpMessage[kPepReplyTo] as? [PEPIdentity]))
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

    public func pEpMessage(outgoing: Bool = true) -> PEPMessage {
        return PEPUtil.pEp(cdMessage: self, outgoing: outgoing)
    }

    public func isProbablyPGPMime() -> Bool {
        return PEPUtil.isProbablyPGPMime(cdMessage: self)
    }
}
