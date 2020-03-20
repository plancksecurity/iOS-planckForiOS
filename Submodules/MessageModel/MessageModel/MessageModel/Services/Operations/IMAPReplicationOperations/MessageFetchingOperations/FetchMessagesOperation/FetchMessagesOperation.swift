//
//  FetchMessagesOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

/// Fetches new messages from the IMAP server for al given folders.
/// - note: the operations MUST NOT run concurrently. Thus we are using a serial queue.
class FetchMessagesOperation: ImapSyncOperation { //BUFF: extracts base class that does something on every interesting folder of one account?
    let folderInfos: [FolderInfo]

    init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         folderInfos: [FolderInfo]) {
        self.folderInfos = folderInfos
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
        backgroundQueue.maxConcurrentOperationCount = 1
    }

    override open func main() {
        scheduleOperations()
        waitForBackgroundTasksAndFinish()
    }
}

// MARK: - Private

extension FetchMessagesOperation {

    private func scheduleOperations() {
        for fi in folderInfos {
            let op = FetchMessagesInImapFolderOperation(errorContainer: errorContainer,
                                                        imapConnection: imapConnection,
                                                        folderName: fi.name)
            backgroundQueue.addOperation(op)
        }
    }
}
