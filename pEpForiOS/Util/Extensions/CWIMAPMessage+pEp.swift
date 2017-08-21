//
//  CWIMAPMessage+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

extension CWIMAPMessage {
    /**
     Creates a `CWIMAPMessage` from a given `PEPMessage`.
     See https://tools.ietf.org/html/rfc2822 for a better understanding of some fields.
     */
    public convenience init(pEpMessage: PEPMessage, mailboxName: String? = nil) {
        if let rawMessageData = pEpMessage[kPepRawMessage] as? Data {
            self.init(data: rawMessageData)
        } else {
            self.init()

            if let from = pEpMessage[kPepFrom] as? PEPIdentity {
                let address = PEPUtil.pantomime(pEpIdentity: from)
                self.setFrom(address)
            }

            if let recipients = pEpMessage[kPepTo] as? NSArray {
                PEPUtil.add(pEpIdentities: recipients as! [PEPIdentity],
                            toPantomimeMessage: self,
                            recipientType: .toRecipient)
            }
            if let recipients = pEpMessage[kPepCC] as? NSArray {
                PEPUtil.add(pEpIdentities: recipients as! [PEPIdentity],
                            toPantomimeMessage: self,
                            recipientType: .ccRecipient)
            }
            if let recipients = pEpMessage[kPepBCC] as? NSArray {
                PEPUtil.add(pEpIdentities: recipients as! [PEPIdentity],
                            toPantomimeMessage: self,
                            recipientType: .bccRecipient)
            }
            if let messageID = pEpMessage[kPepID] as? String {
                self.setMessageID(messageID)
            }
            if let sentDate = pEpMessage[kPepSent] as? Date {
                self.setOriginationDate(sentDate)
            }
            if let shortMsg = pEpMessage[kPepShortMessage] as? String {
                self.setSubject(shortMsg)
            }

            // Go over all references and inReplyTo, and add all the uniques
            // as references, with the inReplyTo last
            // (https://cr.yp.to/immhf/thread.html)
            let allRefsAdded = NSMutableOrderedSet()
            if let refs = pEpMessage[kPepReferences] as? [AnyObject] {
                for ref in refs {
                    allRefsAdded.add(ref)
                }
            }
            if let inReplyTos = pEpMessage[kPepInReplyTo] as? [AnyObject] {
                for inReplyTo in inReplyTos {
                    allRefsAdded.add(inReplyTo)
                }
            }
            self.setReferences(allRefsAdded.array)

            // deal with MIME type

            let attachmentDictsOpt = pEpMessage[kPepAttachments] as? NSArray
            if !MiscUtil.isNilOrEmptyNSArray(attachmentDictsOpt) {
                let encrypted = PEPUtil.isProbablyPGPMime(pEpMessage: pEpMessage)

                // Create multipart mail
                let multiPart = CWMIMEMultipart()
                if encrypted {
                    self.setContentType(Constants.contentTypeMultipartEncrypted)
                    self.setParameter(Constants.protocolPGPEncrypted, forKey: "protocol")
                } else {
                    self.setContentType(Constants.contentTypeMultipartRelated)
                }
                self.setContent(multiPart)

                if !encrypted {
                    if let bodyPart = PEPUtil.bodyPart(pEpMessage: pEpMessage) {
                        multiPart.add(bodyPart)
                    }
                }

                if let attachmentDicts = attachmentDictsOpt {
                    for attachmentDict in attachmentDicts {
                        guard let at = attachmentDict as? [String: NSObject] else {
                            continue
                        }
                        let part = CWPart()
                        part.setContentType(at[kPepMimeType] as? String)
                        if let theData = at[kPepMimeData] as? NSData {
                            part.setContent(theData)
                            part.setSize(theData.length)
                        }

                        if let fileName = at[kPepMimeFilename] as? String {
                            if let cid = fileName.extractCid() {
                                part.setContentID("<\(cid)>")
                                part.setContentDisposition(PantomimeInlineDisposition)
                            } else {
                                part.setFilename(at[kPepMimeFilename] as? String)
                                part.setContentDisposition(PantomimeAttachmentDisposition)
                            }
                        }

                        if !encrypted {
                            // We have to add base64 if this was not encrypted by the engine.
                            // Otherwise, leave it as-is.
                            part.setContentTransferEncoding(PantomimeEncodingBase64)
                        }

                        multiPart.add(part)
                    }
                }
            } else {
                if let body = PEPUtil.bodyPart(pEpMessage: pEpMessage) {
                    self.setContent(body.content())
                    self.setContentType(body.contentType())
                }
            }
            
            if let mName = mailboxName {
                let cwFolder = CWIMAPFolder(name: mName)
                cwFolder.setSelected(true)
                self.setFolder(cwFolder)
                self.setInitialized(true)
            }
        }
    }
}
