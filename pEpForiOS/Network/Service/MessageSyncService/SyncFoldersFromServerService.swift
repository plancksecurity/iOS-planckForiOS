//
//  SyncFoldersFromServerService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol SyncFoldersFromServerServiceDelegate: class {
    /**
     Called if the fetched folder was unknown before, and therefore newly created.
     */
    func didCreate(folder: Folder)
}

class SyncFoldersFromServerService: BackgroundOperationImapService {
    weak var delegate: SyncFoldersFromServerServiceDelegate?
}

extension SyncFoldersFromServerService: SyncFoldersFromServerOperationDelegate {
    func didCreate(cdFolder: CdFolder) {
        delegate?.didCreate(folder: cdFolder.folder())
    }
}

extension SyncFoldersFromServerService: ServiceExecutionProtocol {
    func execute(handler: ServiceFinishedHandler? = nil) {
        let bgID = backgrounder?.beginBackgroundTask(taskName: "SyncFoldersFromServerService")
        let imapLoginOp = LoginImapOperation(parentName: parentName, errorContainer: self,
                                             imapSyncData: imapSyncData)
        let syncFoldersOp = SyncFoldersFromServerOperation(
            parentName: parentName, errorContainer: self, imapSyncData: imapSyncData,
            onlyUpdateIfNecessary: false)
        syncFoldersOp.delegate = self
        syncFoldersOp.addDependency(imapLoginOp)
        syncFoldersOp.completionBlock = { [weak self] in
            syncFoldersOp.completionBlock = nil
            self?.backgrounder?.endBackgroundTask(bgID)
            handler?(self?.error)
        }
        backgroundQueue.addOperations([imapLoginOp, syncFoldersOp], waitUntilFinished: false)
    }
}
