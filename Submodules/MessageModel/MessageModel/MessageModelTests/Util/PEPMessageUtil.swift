//
//  PEPMessageUtil.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 22.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

class PEPMessageUtil {
    /// Creates a basic PEPMessage.
    static func basicMessage(ownAddress: String, attachmentData: Data) -> PEPMessage {
        let theFrom = PEPIdentity(address: ownAddress,
                                  userID: "001",
                                  userName: "001",
                                  isOwn: true)

        let msg = PEPMessage()

        msg.direction = .outgoing
        msg.from = theFrom
        msg.to = [theFrom]
        msg.shortMessage = "This is the subject"
        msg.longMessage = "Really nothing"
        msg.messageID = "not really one"
        msg.references = ["1", "2", "3"]
        msg.inReplyTo = ["4", "5"]

        let attach = PEPAttachment(data: attachmentData)
        attach.contentDisposition = .attachment
        msg.attachments = [attach]

        return msg
    }

    /// Creates a dummy PEPMessage that can be used as input to SendMessageCallbackHandler.
    static func syncMessage(ownAddress: String, attachmentData: Data) -> PEPMessage {
        let msg = basicMessage(ownAddress: ownAddress, attachmentData: attachmentData)
        msg.shortMessage = "This is a sync message"
        return msg
    }
}
