//
//  OutlookSpecificInformation.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.03.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

struct OutlookSpecificInformation {
}

/// Outlook.com/o365 accounts have a special sent folder that is automatically updated
/// when using SMTP. They cannot be told apart from the servers they use,
/// so they share one implementation.
extension OutlookSpecificInformation: ProviderSpecificInformationProtocol {
    func belongsToProvider(_ folder: Folder) -> Bool {
        // Delegate to CdFolder implementation.
        return belongsToProvider(folder.cdObject)
    }

    func belongsToProvider(_ folder: CdFolder) -> Bool {
        let acType = folder.accountOrCrash.accountType
        return acType == .o365 || acType == .outlook
    }

    func isOkToAppendMessages(toFolder folder: Folder) -> Bool {
        // Delegate to CdFolder implementation.
        return isOkToAppendMessages(toFolder: folder.cdObject)
    }

    func isOkToAppendMessages(toFolder folder: CdFolder) -> Bool {
        // Don't append to send, other folders are OK for now.
        return folder.folderType != .sent
    }

    func shouldUidMoveMailsToTrashWhenDeleted(inFolder folder: Folder) -> Bool {
        return true
    }

    func defaultDestructiveActionIsArchive(forFolder folder: Folder) -> Bool {
        // This is not gmail, so delete properly.
        return false
    }
}
