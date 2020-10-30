//
//  SyncMessagesOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

///Syncs existing messages with the servers, e.g., detecting deleted ones.
/// - note: the operations MUST NOT run concurrently. Thus we are using a serial queue.
class SyncMessagesOperation: ConcurrentBaseOperation {
    var imapConnection: ImapConnectionProtocol
    let folderInfos: [FolderInfo]

    required init(parentName: String = #function,
                  context: NSManagedObjectContext? = nil,
                  errorContainer: ErrorContainerProtocol = ErrorPropagator(),
                  imapConnection: ImapConnectionProtocol,
                  folderInfos: [FolderInfo]) { //BUFF: refactor to get account and get interesting folders++ here. The data given when init-ing might be outdated when running the OP
        self.folderInfos = folderInfos
        self.imapConnection = imapConnection
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer)
    }

    override func main() {
        scheduleOperations()
        waitForBackgroundTasksAndFinish()
    }
}

// MARK: - Private

extension SyncMessagesOperation {

    private func scheduleOperations() {
        for fi in folderInfos {
            guard
                let firstUID = fi.firstUID,
                let lastUID = fi.lastUID,
                firstUID != 0, lastUID != 0, firstUID <= lastUID
                else {
                    continue
            }
            let syncMessagesOp = SyncMessagesInImapFolderOperation(errorContainer: errorContainer,
                                                                   imapConnection: imapConnection,
                                                                   folderName: fi.name,
                                                                   firstUID: firstUID,
                                                                   lastUID: lastUID)
            backgroundQueue.addOperation(syncMessagesOp)
        }
    }

}
