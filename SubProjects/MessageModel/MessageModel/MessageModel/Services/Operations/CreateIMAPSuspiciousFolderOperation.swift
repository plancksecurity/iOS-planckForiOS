//
//  CreateIMAPSuspiciousFolderOperation.swift
//  MessageModel
//
//  Created by Martin Brude on 12/1/24.
//  Copyright © 2024 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif


/// Checks if the planck suspicious folder exists and tries to create it if it does not.
class CreateIMAPSuspiciousFolderOperation: ImapSyncOperation {
    /// Whether or not the client or this operation is responsible for saving the context
    private var saveContextWhenDone: Bool

    init(parentName: String = #function,
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
            me.syncDelegate = CreateIMAPSuspiciousFolderOperationSyncDelegate(errorHandler: me)
            me.imapConnection.delegate = me.syncDelegate

            me.privateMOC.performAndWait {
                guard
                    let cdAccount = me.imapConnection.cdAccount(moc: me.privateMOC) else {
                        me.handle(error:
                            BackgroundError.CoreDataError.couldNotFindAccount(info: me.comp))
                        return
                }
                guard CdFolder.by(folderType: .suspicious, account: cdAccount, context: me.privateMOC) == nil
                    else {
                        // suspicious folder exists already. Nothing to do.
                        me.waitForBackgroundTasksAndFinish()
                        return
                }
                me.createPlanckSuspiciousFolder(for: cdAccount)
            }
        }
    }

    private func saveContext() {
        if saveContextWhenDone {
            privateMOC.saveAndLogErrors()
        }
    }

    private func createPlanckSuspiciousFolder(for cdAccount: CdAccount) {
        guard let suspiciousFolderName = createPlanckFolderName(for: cdAccount) else {
                handle(error: BackgroundError.ImapError.invalidAccount)
                return
        }
        imapConnection.createFolderNamed(suspiciousFolderName)
    }

    private func createPlanckFolderName(for cdAccount: CdAccount) -> String? {
        guard
            let seperator = CdFolder.folderSeparatorAsString(cdAccount: cdAccount),
            let inbox = CdFolder.by(folderType: .inbox, account: cdAccount, context: privateMOC),
            let inboxName = inbox.name
            else {
                handle(error: BackgroundError.ImapError.invalidAccount)
                return nil
        }
        let pEpFolderName = inboxName + seperator + CdFolder.planckSuspiciousFolderName
        return pEpFolderName
    }

    /// Creates local planck suspicious folder.
    /// - note: MUST be called on privateMoc
    private func createLocalPlanckFolder() {
        guard
            let cdAccount = imapConnection.cdAccount(moc: privateMOC),
            let inbox = CdFolder.by(folderType: .inbox, account: cdAccount, context: privateMOC),
            let seperator = CdFolder.folderSeparatorAsString(cdAccount: cdAccount),
            let name = createPlanckFolderName(for: cdAccount),
            let localPEPFolder = CdFolder.updateOrCreate(folderName: name,
                                                         folderSeparator: seperator,
                                                         folderType: .suspicious,
                                                         account: cdAccount,
                                                         context: privateMOC)
            else {
                handle(error: BackgroundError.ImapError.invalidAccount)
                return
        }
        localPEPFolder.parent = inbox
    }
}

// MARK: - Callback Handler

extension CreateIMAPSuspiciousFolderOperation {

    fileprivate func handleFolderCreateCompleted() {
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

    fileprivate func handleFolderCreateFailed() {
        // The server refused to let us create a folder. That can happen. GMX free accounts for
        // instance allow 10 custom folders only.
        // We silently ignore those errors.
        waitForBackgroundTasksAndFinish()
    }
}

// MARK: - DefaultImapSyncDelegate

class CreateIMAPSuspiciousFolderOperationSyncDelegate: DefaultImapConnectionDelegate {
    override func folderCreateCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? CreateIMAPSuspiciousFolderOperation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateCompleted()
    }

    override func folderCreateFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? CreateIMAPSuspiciousFolderOperation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateFailed()
    }
}
