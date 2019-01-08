//
//  FolderInfoOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

/**
 Meta data about a folder that is needed to sync existing messages.
 */
protocol FolderUIDInfoProtocol {
    var firstUID: UInt { get }
    var lastUID: UInt { get }

    var valid: Bool { get }
    var empty: Bool { get }
}

extension FolderUIDInfoProtocol {
    var valid: Bool {
        return firstUID > 0 && lastUID > 0 && lastUID >= firstUID
    }

    var empty: Bool {
        let hasElements = Int(lastUID) - Int(firstUID) > 0
        return !hasElements
    }
}

struct FolderUIDInfo: FolderUIDInfoProtocol {
    var firstUID: UInt = 0
    var lastUID: UInt = 0
}

/**
 Determins the folder's first and last UIDs, as they are right now.
 */
class FolderInfoOperation: ConcurrentBaseOperation {
    let accountObjectID: NSManagedObjectID
    let folderName: String
    var folderInfo = FolderUIDInfo()

    private let logger = Logger(category: Logger.backend)

    public init?(parentName: String = #function,
                errorContainer: ServiceErrorProtocol = ErrorContainer(),
                connectInfo: ConnectInfo,
                folderName: String) {
        guard let accountId = connectInfo.accountObjectID else {
            logger.errorAndCrash("No CdAccound ID")
            return nil
        }
        self.accountObjectID = accountId
        self.folderName = folderName
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override func main() {
        if isCancelled {
            markAsFinished()
            return
        }
        let context = privateMOC
        context.perform {
            self.process(context: context)
        }
    }

    func process(context: NSManagedObjectContext) {
        guard
            let cdAccount = context.object(with: accountObjectID) as? CdAccount else {
                handleError(BackgroundError.CoreDataError.couldNotFindAccount(info: nil))
                return
        }
        var theCdFolder: CdFolder?
        if folderName.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            theCdFolder = CdFolder.by(folderType: .inbox, account: cdAccount)
        } else {
            theCdFolder = CdFolder.by(name: folderName, account: cdAccount)
        }
        guard
            let cdFolder = theCdFolder else {
                handleError(BackgroundError.CoreDataError.couldNotFindFolder(info: nil))
                return
        }
        folderInfo.firstUID = cdFolder.firstUID()
        folderInfo.lastUID = cdFolder.lastUID()
        markAsFinished()
    }
}

extension FolderInfoOperation: FolderUIDInfoProtocol {
    var firstUID: UInt {
        return folderInfo.firstUID
    }

    var lastUID: UInt {
        return folderInfo.lastUID
    }
}
