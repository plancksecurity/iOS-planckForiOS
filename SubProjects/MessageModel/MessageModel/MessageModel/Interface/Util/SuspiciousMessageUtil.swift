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

    /// Indicates if the message passed has to be moved to the suspicious folder. True if it has to be moved.
    public static func shouldMoveToSuspiciousFolder(message: Message) -> Bool {
        guard let pEprating = PEPRating(rawValue: Int32(message.cdObject.pEpRating)) else {
            return false
        }
        let isDangerousMessage = Rating(pEpRating: pEprating).isDangerous()
        let isFolderWrong = isFolderWrong(type: message.parent.folderType)
        return isDangerousMessage && isFolderWrong
    }

    private static func isFolderWrong(type: FolderType) -> Bool {
        let foldersToSkip: [FolderType] = [.suspicious, .sent, .pEpSync, .trash, .outbox, .drafts]
        return foldersToSkip.allSatisfy { $0 != type }
    }
}
