//
//  ImapFolderBuilder.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class ImapFolderBuilder: NSObject, CWFolderBuilding {
    public var folderNameToIgnore: String?

    let accountID: NSManagedObjectID
    open let backgroundQueue: OperationQueue?
    let name: String?
    let messageFetchedBlock: MessageFetchedBlock?

    public init(accountID: NSManagedObjectID, backgroundQueue: OperationQueue,
                name: String? = nil, messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.backgroundQueue = backgroundQueue
        self.name = name
        self.messageFetchedBlock = messageFetchedBlock
    }

    open func folder(withName: String) -> CWFolder {
        if folderNameToIgnore != nil && withName == folderNameToIgnore {
            return CWFolder(name: withName)
        } else {
            return PersistentImapFolder(
                name: withName, accountID: accountID, backgroundQueue: backgroundQueue!,
                logName: name, messageFetchedBlock: messageFetchedBlock) as CWFolder
        }
    }

    deinit {
        Log.info(component: "ImapFolderBuilder: \(name)", content: "ImapFolderBuilder.deinit")
    }
}
