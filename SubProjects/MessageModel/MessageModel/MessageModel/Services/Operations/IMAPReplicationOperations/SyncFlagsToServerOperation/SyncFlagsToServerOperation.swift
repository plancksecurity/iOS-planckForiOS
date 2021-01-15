//
//  SyncFlagsToServerOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PantomimeFramework
import pEpIOSToolbox

/// Sends (syncs) local changes of Imap flags to server for all given folders.
/// - note: the operations MUST NOT run concurrently. Thus we are using a serial queue.
class SyncFlagsToServerOperation: ConcurrentBaseOperation {
    let folderInfos: [FolderInfo]
    var imapConnection: ImapConnectionProtocol

    required init(parentName: String = #function,
                  context: NSManagedObjectContext? = nil,
                  errorContainer: ErrorContainerProtocol = ErrorPropagator(),
                  imapConnection: ImapConnectionProtocol,
                  folderInfos: [FolderInfo]) { //BUFF: refactor to get account and get interesting folders++ here. The data given when init-ing might be outdated when
        self.folderInfos = folderInfos
        self.imapConnection = imapConnection
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer)
        backgroundQueue.maxConcurrentOperationCount = 1
    }
    
    override func main() {
        scheduleOperations()
        waitForBackgroundTasksAndFinish()
    }
}

// MARK: - Private

extension SyncFlagsToServerOperation {

    private func scheduleOperations() {
        for fi in folderInfos {
            guard let folderID = fi.folderID else {
                Log.shared.errorAndCrash("No folder ID")
                continue
            }
            let op = SyncFlagsToServerInImapFolderOperation(errorContainer: errorContainer,
                                                            imapConnection: imapConnection,
                                                            folderID: folderID)
            backgroundQueue.addOperation(op)
        }
    }
}
