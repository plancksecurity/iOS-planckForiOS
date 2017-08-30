//
//  StoreFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

protocol StoreFolderOperationDelegate: class {
    /**
     Called if the folder was unknown before, and therefore newly created.
     */
    func didCreate(cdFolder: CdFolder)
}

public class StoreFolderOperation: ConcurrentBaseOperation {
    public struct FolderInfo {
        let name: String
        let separator: String?
        let folderType: FolderType?
    }
    
    let folderInfo: FolderInfo
    let connectInfo: EmailConnectInfo

    weak var delegate: StoreFolderOperationDelegate?

    init(parentName: String = #function, connectInfo: EmailConnectInfo, folderInfo: FolderInfo) {
        self.folderInfo = folderInfo
        self.connectInfo = connectInfo
        super.init(parentName: parentName)
        Log.verbose(component: comp, content: "init \(folderInfo.name)")
    }

    override public func main() {
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

        if let (cdFolder, newlyCreated) = CdFolder.insertOrUpdate(
            folderName: folderInfo.name,
            folderSeparator: folderInfo.separator,
            folderType: folderInfo.folderType,
            account: account) {
            if newlyCreated {
                delegate?.didCreate(cdFolder: cdFolder)
            }
        } else {
            self.addError(Constants.errorCouldNotStoreFolder(comp, name: folderInfo.name))
        }

        Record.saveAndWait()
        self.markAsFinished()
    }
}
