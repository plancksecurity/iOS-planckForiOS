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
        return belongsToProvider(folder.cdObject)
    }

    func belongsToProvider(_ folder: CdFolder) -> Bool {
        return false
    }

    func isOkToAppendMessages(toFolder folder: Folder) -> Bool {
        return false
    }

    func isOkToAppendMessages(toFolder folder: CdFolder) -> Bool {
        return false
    }

    func isVirtualMailbox(_ folder: Folder) -> Bool {
        return false
    }

    func shouldUidMoveMailsToTrashWhenDeleted(inFolder folder: Folder) -> Bool {
        return false
    }

    func defaultDestructiveActionIsArchive(forFolder folder: Folder) -> Bool {
        return false
    }
}
