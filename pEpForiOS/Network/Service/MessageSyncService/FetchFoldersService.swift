//
//  FetchFoldersService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol FetchFoldersServiceDelegate: class {
    /**
     Called if the fetched folder was unknown before, and therefore newly created.
     */
    func didCreate(folder: Folder)
}

class FetchFoldersService: BackgroundOperationImapService {
    weak var delegate: FetchFoldersServiceDelegate?
}

extension FetchFoldersService: FetchFoldersOperationOperationDelegate {
    func didCreate(cdFolder: CdFolder) {
        delegate?.didCreate(folder: cdFolder.folder())
    }
}

extension FetchFoldersService: ServiceExecutionProtocol {
    func execute(handler: ServiceFinishedHandler? = nil) {
        let bgID = backgrounder?.beginBackgroundTask(taskName: "FetchFoldersService")
        let imapLoginOp = LoginImapOperation(parentName: parentName, errorContainer: self,
                                             imapSyncData: imapSyncData)
        let fetchFoldersOp = FetchFoldersOperation(
            parentName: parentName, errorContainer: self, imapSyncData: imapSyncData,
            onlyUpdateIfNecessary: false)
        fetchFoldersOp.delegate = self
        fetchFoldersOp.addDependency(imapLoginOp)
        fetchFoldersOp.completionBlock = { [weak self] in
            fetchFoldersOp.completionBlock = nil
            self?.backgrounder?.endBackgroundTask(bgID)
            handler?(self?.error)
        }
        backgroundQueue.addOperations([imapLoginOp, fetchFoldersOp], waitUntilFinished: false)
    }
}
