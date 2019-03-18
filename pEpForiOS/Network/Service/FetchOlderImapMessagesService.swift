//
//  FetchOlderImapMessagesService.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

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
                Logger.backendLogger.error(
                    "nconsistent DB state. CDFolder for Folder %{public}@ does not exist or its mandatory field \"account\" is not set.",
                    folder.name)
                return
        }
        guard let imapConnectInfo = cdAccount.imapConnectInfo else {
            return
        }
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()
        let loginOp = LoginImapOperation(
            parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData)
        let fetchOlderOp = FetchOlderImapMessagesOperation(errorContainer: errorContainer, imapSyncData: imapSyncData, folderName: folder.name)
        fetchOlderOp.completionBlock = {[weak self] in
            self?.removeFromRunning(opForFolder: folder)
            let decryptOP = DecryptMessagesOperation(errorContainer: errorContainer)
            self?.queue.addOperation(decryptOP)
        }
        runningOperations[folder] = fetchOlderOp
        queue.addOperation(loginOp)
        queue.addOperation(fetchOlderOp)
    }

    func removeFromRunning(opForFolder folder: Folder) {
        runningOperations[folder] = nil
    }

    private func anOperationIsAlreadyRunning(forFolder folder: Folder) -> Bool {
        return runningOperations[folder] != nil
    }
}
