//
//  AppendMailsOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 12.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/// IMAP Appends all mails that need append for one account.
/// - note: the operations MUST NOT run concurrently. Thus we are using a serial queue.
class AppendMailsOperation: ConcurrentBaseOperation {
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
    }

    override func main() {
        scheduleOperations()
        waitForBackgroundTasksAndFinish()
    }
}

// MARK: - Private

extension AppendMailsOperation {

    private func scheduleOperations() {
        changePropagatorMoc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard !me.isCancelled else {
                return
            }
            let folders = me.foldersContainingMarkedForAppend()
            for folder in folders {
                let op = AppendMailsToFolderOperation(folder: folder,
                                                      errorContainer: me.errorContainer,
                                                      imapConnection: me.imapConnection)
                me.backgroundQueue.addOperation(op)
            }
        }
    }

    private func foldersContainingMarkedForAppend() -> [CdFolder] {
        guard
            let cdAccount = imapConnection.cdAccount(moc: changePropagatorMoc)
            else {
                Log.shared.errorAndCrash("No account")
                return []
        }
        let appendMessages = CdMessage.allMessagesMarkedForAppend(inAccount: cdAccount,
                                                                  context: changePropagatorMoc)
        let foldersContainingMessagesForAppend = appendMessages.compactMap { $0.parent }
        return Array(Set(foldersContainingMessagesForAppend))
    }
}
