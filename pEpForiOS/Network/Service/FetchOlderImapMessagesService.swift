//
//  FetchOlderImapMessagesService.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

public class FetchOlderImapMessagesService {
    var runningOperations = [Folder:BaseOperation]()
    let queue: OperationQueue

    public init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated //I tend to use -utility, it is actually userInitiated though. Let's see if it blocks the UI somehow...
    }

    public func fetchOlderMessages(inFolder folder: Folder) {
        if anOperationIsAlreadyRunning(forFolder: folder) {
            return
        }

        guard let cdFolder = CdFolder.search(folder: folder),
            let cdAccount = cdFolder.account else {
                Log.shared.error(component: #function,
                                 errorString: "Inconsistent DB state. CDFolder for Folder \(folder) does not exist or its mandatory field \"account\" is not set.")
                //BUFF: if we introduce a delegate, please inform her.
                return
        }
        guard let imapConnectInfo = cdAccount.imapConnectInfo else {
            //BUFF: if we introduce a delegate, please inform her.
            return
        }
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()
        let loginOp = LoginImapOperation(
            parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData)
        let fetchOlderOp = FetchOlderImapMessagesOperation(errorContainer: errorContainer, imapSyncData: imapSyncData, folderName: folder.name)
        fetchOlderOp.completionBlock = {[weak self] in
            self?.removeFromRunning(opForFolder: folder)
        }
        runningOperations[folder] = fetchOlderOp
        queue.addOperation(loginOp)
        queue.addOperation(fetchOlderOp)
    }

    func removeFromRunning(opForFolder folder: Folder) {
        guard let runningOp = runningOperations[folder] else {
            return
        }
        runningOp.cancel()
    }

    private func anOperationIsAlreadyRunning(forFolder folder: Folder) -> Bool {
        return runningOperations[folder] != nil
    }
}
