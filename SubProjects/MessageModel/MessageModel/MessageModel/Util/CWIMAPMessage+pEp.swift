//
//  CWIMAPMessage+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import PantomimeFramework
import PEPObjCAdapter

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

extension CWIMAPMessage {

    /// Creates a `CWIMAPMessage` from a given `PEPMessage`.
    /// - seeAlso: https://tools.ietf.org/html/rfc2822 for a better understanding of some fields.
    convenience init(pEpMessage: PEPMessage, mailboxName: String? = nil) {
        self.init()

        if let from = pEpMessage.from {
            let address = from.pantomimeAddress()
            self.setFrom(address)
        }

        if let recipients = pEpMessage.to {
            PEPIdentity.add(pEpIdentities: recipients,
                            toPantomimeMessage: self,
                            recipientType: .toRecipient)
        }
        if let recipients = pEpMessage.cc {
            PEPIdentity.add(pEpIdentities: recipients,
                            toPantomimeMessage: self,
                            recipientType: .ccRecipient)
        }
        if let recipients = pEpMessage.bcc {
            PEPIdentity.add(pEpIdentities: recipients,
                            toPantomimeMessage: self,
                            recipientType: .bccRecipient)
        }
        if let messageID = pEpMessage.messageID {
            self.setMessageID(messageID)
        }
        if let sentDate = pEpMessage.sentDate {
            self.setOriginationDate(sentDate)
        }
        if let shortMsg = pEpMessage.shortMessage {
            self.setSubject(shortMsg)
        }

        // Go over all references and inReplyTo, and add all the uniques
        // as references, with the inReplyTo last
        // (https://cr.yp.to/immhf/thread.html)
        var allRefsToAdd = [String]()
        if let refs = pEpMessage.references {
            for ref in refs {
                allRefsToAdd.append(ref)
            }
        }
        if let inReplyTos = pEpMessage.inReplyTo {
            for inReplyTo in inReplyTos {
                allRefsToAdd.append(inReplyTo)
            }
        }
        self.setReferences(allRefsToAdd)

        if let optFields = pEpMessage.optionalFields {
            for headerfield in optFields {
                addHeader(headerfield[0], withValue: headerfield[1])
            }
        }

        setContentDisposition(PantomimeInlineDisposition)

        let attachmentDicts = pEpMessage.attachments ?? []
        if !attachmentDicts.isEmpty {
            let isEncrypted = pEpMessage.isProbablyPGPMime()

            // Create multipart mail
            let multiPart = CWMIMEMultipart()
            if isEncrypted {
                self.setContentType(ContentTypeUtils.ContentType.multipartEncrypted)
                self.setContentTransferEncoding(PantomimeEncoding8bit)
                self.setParameter(MimeTypeUtils.MimeType.pgpEncrypted.rawValue, forKey: "protocol")
            } else {
                self.setContentType(ContentTypeUtils.ContentType.multipartRelated)
                self.setContentTransferEncoding(PantomimeEncoding8bit)
                if let bodyPart = PEPUtils.bodyPart(pEpMessage: pEpMessage) {
                    multiPart.add(bodyPart)
                }
            }
            self.setContent(multiPart)

            for attachmentObj in attachmentDicts {
                let part = CWPart()
                part.setContentType(attachmentObj.mimeType)
                part.setContent(attachmentObj.data as NSObject)
                part.setSize(attachmentObj.size)

                let pantomimeContentDisposition =
                    attachmentObj.contentDisposition.pantomimeContentDisposition
                part.setContentDisposition(pantomimeContentDisposition)

                if let fileName = attachmentObj.filename {
                    if let cid = fileName.extractCid() {
                        part.setContentID("<\(cid)>")
                        let placeholderFilename = NSLocalizedString("image",
                                                                    comment: "Placeholder filename used for inlined images (as the real filename is lost due to the Engine message having only one field for content-id, filename and name)")
                        part.setFilename(placeholderFilename)
                    } else {
                        let theFilePart = fileName.extractFileName() ?? fileName
                        part.setFilename(theFilePart)
                    }
                }

                if !isEncrypted {
                    // We have to add base64 if this was not encrypted by the engine.
                    // Otherwise, leave it as-is.
                    part.setContentTransferEncoding(PantomimeEncodingBase64)
                }

                multiPart.add(part)
            }
        } else {
            if let body = PEPUtils.bodyPart(pEpMessage: pEpMessage) {
                self.setContent(body.content())
                self.setContentType(body.contentType())
                if body.contentTransferEncoding() != PantomimeEncodingNone {
                    self.setContentTransferEncoding(body.contentTransferEncoding())
                } else {
                    self.setContentTransferEncoding(PantomimeEncoding8bit)
                }
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
