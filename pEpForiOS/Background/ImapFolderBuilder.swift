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
    let guaranteedBackgroundQueue: OperationQueue
    let name: String?
    let messageFetchedBlock: MessageFetchedBlock?

    open var backgroundQueue: OperationQueue? {
        return guaranteedBackgroundQueue
    }

    public init(accountID: NSManagedObjectID, backgroundQueue: OperationQueue,
                name: String? = nil, messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.guaranteedBackgroundQueue = backgroundQueue
        self.name = name
        self.messageFetchedBlock = messageFetchedBlock
    }

    open func folder(withName: String) -> CWFolder {
        if folderNameToIgnore != nil && withName == folderNameToIgnore {
            Logger.backendLogger.warn("ignoring folder %{public}@", withName)
            return CWFolder(name: withName)
        } else {
            if let theFolder = PersistentImapFolder(
                name: withName, accountID: accountID, backgroundQueue: guaranteedBackgroundQueue,
                logName: name, messageFetchedBlock: messageFetchedBlock) {
                return theFolder
            } else {
                return CWFolder(name: withName)
            }
        }
    }
}
