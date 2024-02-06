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
        let currentFolderType = message.parent.folderType
        let isDangerousMessage = Rating(pEpRating: pEprating).isDangerous()
        let isFolderWrong = [FolderType.suspicious, FolderType.sent, FolderType.pEpSync, FolderType.trash].contains(where: {$0 != currentFolderType})
        return isDangerousMessage && isFolderWrong
    }
}
