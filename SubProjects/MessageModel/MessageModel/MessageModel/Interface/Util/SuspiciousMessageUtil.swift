//
//  SuspiciousMessageUtil.swift
//  MessageModel
//
//  Created by Martin Brude on 15/1/24.
//  Copyright © 2024 pEp Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapter

public class SuspiciousMessageUtil {

    public static func shouldMoveToSuspiciousFolder(message: Message) -> Bool {
        guard let pEprating = PEPRating(rawValue: Int32(message.cdObject.pEpRating)) else {
            return false
        }
        return Rating(pEpRating: pEprating).isDangerous() && message.parent.folderType != .suspicious
    }

    public static func moveMessageToSuspiciousFolderIfNeeded(message: Message) {
        guard shouldMoveToSuspiciousFolder(message: message) else {
            return
        }
        guard let folder = Folder.getSuspiciousFolder(account: message.parent.account) else {
            return
        }
        Message.move(messages: [message], to: folder)
    }
}

