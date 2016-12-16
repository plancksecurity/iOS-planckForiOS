//
//  StoreFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

struct FolderInfo {
    let name: String
    let separator: String?
}

class StoreFolderOperation: ConcurrentBaseOperation {
    let folderInfo: FolderInfo
    let connectInfo: EmailConnectInfo

    init(connectInfo: EmailConnectInfo, folderInfo: FolderInfo) {
        self.folderInfo = folderInfo
        self.connectInfo = connectInfo
        super.init()
        Log.info(component: comp, content: "init \(folderInfo.name)")
    }

    override func main() {
        Log.verbose(component: comp, content: "main \(folderInfo.name)")
        let privateMOC = Record.Context.default
        privateMOC.perform({
            self.process(context: privateMOC)
        })
    }

    func process(context: NSManagedObjectContext) {
        Log.verbose(component: comp, content: "process \(folderInfo.name)")
        guard let account = context.object(with: connectInfo.accountObjectID)
            as? CdAccount else {
                addError(Constants.errorCannotFindAccount(component: comp))
                return
        }

        if let server = context.object(with: connectInfo.serverObjectID) as? CdServer {
            server.imapFolderSeparator = folderInfo.separator
        }

        let folder = CdFolder.insertOrUpdate(
            folderName: folderInfo.name, folderSeparator: folderInfo.separator,
            account: account)

        if folder == nil {
            self.addError(Constants.errorCouldNotStoreFolder(comp, name: folderInfo.name))
        }

        Record.saveAndWait()
        self.markAsFinished()
    }
}
