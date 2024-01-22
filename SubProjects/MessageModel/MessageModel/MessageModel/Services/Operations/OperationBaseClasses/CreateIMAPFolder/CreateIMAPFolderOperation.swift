//
//  CreateIMAPFolderOperation.swift
//  MessageModel
//
//  Created by Martin Brude on 22/1/24.
//  Copyright © 2024 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

protocol ErrorHandlerDelegate: ImapSyncOperation {
    func handleFolderCreateCompleted()
    func handleFolderCreateFailed()
}

class CreateIMAPFolderOperation: ImapSyncOperation {

    private var saveContextWhenDone: Bool

    init(parentName: String,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         saveContextWhenDone: Bool = true) {
        self.saveContextWhenDone = saveContextWhenDone
        super.init(context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    override func main() {
        if !checkImapConnection() {
            waitForBackgroundTasksAndFinish()
            return
        }
        process()
    }

    private func process() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.syncDelegate = me.createSyncDelegate()
            me.imapConnection.delegate = me.syncDelegate

            me.privateMOC.performAndWait {
                guard let cdAccount = me.imapConnection.cdAccount(moc: me.privateMOC) else {
                    me.handle(error: BackgroundError.CoreDataError.couldNotFindAccount(info: me.comp))
                    return
                }
                guard !me.folderExists(for: cdAccount) else {
                    me.waitForBackgroundTasksAndFinish()
                    return
                }
                me.createFolder(for: cdAccount)
            }
        }
    }

    func saveContext() {
        if saveContextWhenDone {
            privateMOC.saveAndLogErrors()
        }
    }

    // MARK: - Must subclass

    func createSyncDelegate() -> ImapConnectionDelegate? {
        Log.shared.errorAndCrash("The subclass must implement this method")
        return nil
    }

    func folderExists(for cdAccount: CdAccount) -> Bool {
        Log.shared.errorAndCrash("The subclass must implement this method")
        return false
    }

    func createFolder(for cdAccount: CdAccount) {
        Log.shared.errorAndCrash("The subclass must implement this method")
    }
    
    func createLocalPlanckFolder() {
        Log.shared.errorAndCrash("The subclass must implement this method")
    }
}

extension CreateIMAPFolderOperation: ErrorHandlerDelegate {

    func handleFolderCreateCompleted() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.privateMOC.performAndWait {
                me.createLocalPlanckFolder()
                me.saveContext()
                me.waitForBackgroundTasksAndFinish()
            }
        }
    }

    func handleFolderCreateFailed() {
        // The server refused to let us create a folder. That can happen. GMX free accounts for
        // instance allow 10 custom folders only.
        // We silently ignore those errors.
        waitForBackgroundTasksAndFinish()
    }
}
