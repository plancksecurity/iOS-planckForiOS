//
//  FolderModelOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

/**
 Loads all folders for a given account and stores it in an array
 easily usable by table views.
 */
public class FolderModelOperation: ConcurrentBaseOperation {
    public struct FolderItem {
        public let objectID: NSManagedObjectID
        public let name: String
        public let type: FolderType
        public let level: Int
        public let numberOfMessages: Int
    }

    /** The account email for which to load all the folders */
    var accountEmail: String

    /**
     The result of running the operation: A list of folders for the account,
     complete with indentation level.
     - Note: Traversal must be depth-first, so after each folder all children
     are listed.
     */
    public var folderItems = [FolderItem]()

    public init(account: IAccount, coreDataUtil: ICoreDataUtil) {
        self.accountEmail = account.email
        super.init(coreDataUtil: coreDataUtil)
    }

    override public func main() {
        let ctx = coreDataUtil.privateContext()
        ctx.performBlock({
            let model = Model.init(context: ctx)

            let predicateParent = NSPredicate.init(format: "parent == nil")
            let predicateAccount = NSPredicate.init(
                format: "account.email = %@", self.accountEmail)
            let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: [predicateParent, predicateAccount])
            guard let folders = model.foldersByPredicate(predicate, sortDescriptors: nil)
                else {
                    return
            }
            for fol in folders {
                self.processFolder(fol, level: 0)
            }

            self.markAsFinished()
        })
    }

    func processFolder(folder: IFolder, level: Int) {
        // TODO: numberOfMessages really should be the number of unread messages
        let item = FolderItem.init(
            objectID: (folder as! Folder).objectID, name: folder.name,
            type: FolderType.fromNumber(folder.folderType)!, level: level,
            numberOfMessages: 0)
        folderItems.append(item)

        for fol in folder.children {
            if let f = fol as? IFolder {
                processFolder(f, level: level + 1)
            }
        }
    }
}