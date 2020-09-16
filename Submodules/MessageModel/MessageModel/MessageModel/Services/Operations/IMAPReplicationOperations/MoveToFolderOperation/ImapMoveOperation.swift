//
//  ImapMoveOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 12.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PantomimeFramework

/// IMAP MOVEs all messages marked to move to the specified `targetFolder`.
/// - note: the operations MUST NOT run concurrently. Thus we are using a serial queue.
class ImapMoveOperation: ConcurrentBaseOperation {
    var imapConnection: ImapConnectionProtocol
    let changePropagatorMoc: NSManagedObjectContext = Stack.shared.changePropagatorContext

    required init(parentName: String = #function,
                  context: NSManagedObjectContext? = nil,
                  errorContainer: ErrorContainerProtocol = ErrorPropagator(),
                  imapConnection: ImapConnectionProtocol) {
        self.imapConnection = imapConnection
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer)
        backgroundQueue.maxConcurrentOperationCount = 1
    }

    override public func main() {
        scheduleOperations()
        waitForBackgroundTasksAndFinish()
    }
}

// MARK: - Private

extension ImapMoveOperation {

    private func scheduleOperations() {
        changePropagatorMoc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let folders = me.foldersContainingMarkedForMoveToFolder()
            for folder in folders {
                let op = MoveToFolderOperation(imapConnection: me.imapConnection,
                                               errorContainer: me.errorContainer,
                                               folder: folder)
                me.backgroundQueue.addOperation(op)
            }
        }
    }

    private func foldersContainingMarkedForMoveToFolder() -> [CdFolder] {
        guard let cdAccount = imapConnection.cdAccount(moc: changePropagatorMoc) else {
            Log.shared.errorAndCrash("No account")
            return []
        }
        let allUidMoveMessages = CdMessage.allMessagesMarkedForMoveToFolder(inAccount: cdAccount,
                                                                            context: changePropagatorMoc)
        let foldersContainingMarkedMessages = allUidMoveMessages.compactMap() { $0.parent }
        return Array(Set(foldersContainingMarkedMessages))
    }
}
