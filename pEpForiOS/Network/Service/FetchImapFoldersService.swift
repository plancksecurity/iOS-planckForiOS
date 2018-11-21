//
//  FetchImapFoldersService.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 21/11/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol FetchImapFoldersServiceDelegate: class {
    func finishedSyncingFolders(forAccount account: Account)
}

public class FetchImapFoldersService {
    weak var delegate : FetchImapFoldersServiceDelegate?
    
    var runningOperations = [Folder:BaseOperation]()
    let queue: OperationQueue
    
    public init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated //I tend to use -utility, it is actually userInitiated though. Let's see if it blocks the UI somehow...
    }
    
    func fetchFolders(inAccount account: Account) {
        guard let connectInfo = account.imapConnectInfo else {
            return
        }
        let imapSyncData = ImapSyncData(connectInfo: connectInfo)
        let errorContainer = ErrorContainer()
        let loginOp = LoginImapOperation(
            parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData)
        guard let folderOp = SyncFoldersFromServerOperation(parentName: #function, imapSyncData: imapSyncData) else {
            return
            
        }
        folderOp.completionBlock = { [weak self] in
            self?.delegate?.finishedSyncingFolders(forAccount: account)
            folderOp.completionBlock = nil
        }
        folderOp.addDependency(loginOp)
        
        queue.addOperation(loginOp)
        queue.addOperation(folderOp)
    }
}
