//
//  FetchFoldersService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class FetchFoldersService: AtomicImapService {
    func execute(
        imapSyncData: ImapSyncData,
        handler: ((_ error: Error?) -> ())? = nil) {
        let bgID = backgrounder?.beginBackgroundTask(taskName: "FetchFoldersService")
        let imapLoginOp = LoginImapOperation(parentName: parentName, errorContainer: self,
                                             imapSyncData: imapSyncData)
        let fetchFoldersOp = FetchFoldersOperation(
            parentName: parentName, errorContainer: self, imapSyncData: imapSyncData,
            onlyUpdateIfNecessary: false, messageFetchedBlock: nil)
        fetchFoldersOp.addDependency(imapLoginOp)
        fetchFoldersOp.completionBlock = { [weak self] in
            self?.backgrounder?.endBackgroundTask(bgID)
            handler?(self?.error)
        }
        backgroundQueue.addOperations([imapLoginOp, fetchFoldersOp], waitUntilFinished: false)
    }
}
