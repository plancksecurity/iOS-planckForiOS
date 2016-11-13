//
//  StoreFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

struct FolderInfo {
    let name: String
    let separator: String?
}

class StoreFolderOperation: ConcurrentBaseOperation {
    let comp = "StoreFolderOperation"
    let folderInfo: FolderInfo
    let connectInfo: EmailConnectInfo

    init(connectInfo: EmailConnectInfo, folderInfo: FolderInfo) {
        self.folderInfo = folderInfo
        self.connectInfo = connectInfo
    }

    override func main() {
        let privateMOC = Record.Context.default
        privateMOC.perform({
            self.process(context: privateMOC)
        })
    }

    func process(context: NSManagedObjectContext) {
        guard let account = context.object(with: connectInfo.accountObjectID)
            as? MessageModel.CdAccount else {
                errors.append(Constants.errorCannotFindAccount(component: comp))
                return
        }

        if let server = context.object(with: connectInfo.serverObjectID) as? CdServer {
            server.imapFolderSeparator = folderInfo.separator
        }

        let folder = CdFolder.insertOrUpdate(
            folderName: folderInfo.name, folderSeparator: folderInfo.separator,
            account: account)

        if folder == nil {
            self.errors.append(Constants.errorCouldNotStoreFolder(comp, name: folderInfo.name))
        }

        Record.saveAndWait()
        self.markAsFinished()
    }
}
