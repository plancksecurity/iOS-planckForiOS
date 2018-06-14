//
//  CWIMAPMessage+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CWIMAPMessage {
    /**
     Creates a `CWIMAPMessage` from a given `PEPMessage`.
     See https://tools.ietf.org/html/rfc2822 for a better understanding of some fields.
     */
    public convenience init(pEpMessageDict: PEPMessageDict, mailboxName: String? = nil) {
        self.init()

        if let from = pEpMessageDict[kPepFrom] as? PEPIdentity {
            let address = PEPUtil.pantomime(pEpIdentity: from)
            self.setFrom(address)
        }

        if let recipients = pEpMessageDict[kPepTo] as? [PEPIdentity] {
            PEPUtil.add(pEpIdentities: recipients,
                        toPantomimeMessage: self,
                        recipientType: .toRecipient)
        }
        if let recipients = pEpMessageDict[kPepCC] as? [PEPIdentity] {
            PEPUtil.add(pEpIdentities: recipients,
                        toPantomimeMessage: self,
                        recipientType: .ccRecipient)
        }
        if let recipients = pEpMessageDict[kPepBCC] as? [PEPIdentity] {
            PEPUtil.add(pEpIdentities: recipients,
                        toPantomimeMessage: self,
                        recipientType: .bccRecipient)
        }
        if let messageID = pEpMessageDict[kPepID] as? String {
            self.setMessageID(messageID)
        }
        if let sentDate = pEpMessageDict[kPepSent] as? Date {
            self.setOriginationDate(sentDate)
        }
        if let shortMsg = pEpMessageDict[kPepShortMessage] as? String {
            self.setSubject(shortMsg)
        }

        // Go over all references and inReplyTo, and add all the uniques
        // as references, with the inReplyTo last
        // (https://cr.yp.to/immhf/thread.html)
        var allRefsToAdd = [String]()
        if let refs = pEpMessageDict[kPepReferences] as? [AnyObject] {
            for case let ref as String in refs {
                allRefsToAdd.append(ref)
            }
        }
        if let inReplyTos = pEpMessageDict[kPepInReplyTo] as? [AnyObject] {
            for case let inReplyTo as String in inReplyTos {
                allRefsToAdd.append(inReplyTo)
            }
        }
        self.setReferences(allRefsToAdd)

        if let optFields = pEpMessageDict[kPepOptFields] as? NSArray {
            for item in optFields {
                if let headerfield = item as? NSArray {
                    guard let header = headerfield[0] as? String else {
                        continue
                    }
                    guard let value = headerfield[1] as? String else {
                        continue
                    }
                    addHeader(header, withValue: value)
                }
            }
        }

        let attachmentDictsOpt = pEpMessageDict[kPepAttachments] as? NSArray
        if !MiscUtil.isNilOrEmptyNSArray(attachmentDictsOpt) {
            let encrypted = PEPUtil.isProbablyPGPMime(pEpMessageDict: pEpMessageDict)

            // Create multipart mail
            let multiPart = CWMIMEMultipart()
            if encrypted {
                self.setContentType(Constants.contentTypeMultipartEncrypted)
                self.setContentTransferEncoding(PantomimeEncoding8bit)
                self.setParameter(Constants.protocolPGPEncrypted, forKey: "protocol")
            } else {
                self.setContentType(Constants.contentTypeMultipartRelated)
                self.setContentTransferEncoding(PantomimeEncoding8bit)
                if let bodyPart = PEPUtil.bodyPart(pEpMessageDict: pEpMessageDict) {
                    multiPart.add(bodyPart)
                }
            }
            self.setContent(multiPart)

            if let attachmentObjs = attachmentDictsOpt as? [PEPAttachment] {
                for attachmentObj in attachmentObjs {
                    let part = CWPart()
                    part.setContentType(attachmentObj.mimeType)
                    part.setContent(attachmentObj.data as NSObject)
                    part.setSize(attachmentObj.data.count)

                    let pantomimeContentDisposition =
                        attachmentObj.contentDisposition.pantomimeContentDisposition
                    part.setContentDisposition(pantomimeContentDisposition)
                    
                    if let fileName = attachmentObj.filename {
                        if let cid = fileName.extractCid() {
                            part.setContentID("<\(cid)>")
                        } else {
                            let theFilePart = fileName.extractFileName() ?? fileName
                            part.setFilename(theFilePart)
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
            if let body = PEPUtil.bodyPart(pEpMessageDict: pEpMessageDict) {
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
