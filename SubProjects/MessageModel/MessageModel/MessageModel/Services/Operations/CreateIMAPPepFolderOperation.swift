//
//  CreateIMAPPepFolderOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 24.06.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation


import UIKit
import CoreData

#if EXT_SHARE
import PEPIOSToolboxForAppExtensions
#else
import pEpIOSToolbox
#endif

/// Checks if the pEp folder (used for pEp Sync messages) exists and tries to create it if it
/// does not.
class CreateIMAPPepFolderOperation: ImapSyncOperation {
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
            me.syncDelegate = CreateIMAPPepFolderOperationSyncDelegate(errorHandler: me)
            me.imapConnection.delegate = me.syncDelegate

            me.privateMOC.performAndWait {
                guard
                    let cdAccount = me.imapConnection.cdAccount(moc: me.privateMOC) else {
                        me.handle(error:
                            BackgroundError.CoreDataError.couldNotFindAccount(info: me.comp))
                        return
                }
                guard
                    CdFolder.by(folderType: .pEpSync,
                                account: cdAccount,
                                context: me.privateMOC) == nil
                    else {
                        // pEp folder exists already. Nothing to do.
                        me.waitForBackgroundTasksAndFinish()
                        return
                }
                me.createPEPFolder(for: cdAccount)
            }
        }
    }

    private func savecontext() {
        if saveContextWhenDone {
            privateMOC.saveAndLogErrors()
        }
    }

    private func createPEPFolder(for cdAccount: CdAccount) {
        guard let pEpFolderName = createPepFolderName(for: cdAccount) else {
                handle(error: BackgroundError.ImapError.invalidAccount)
                return
        }
        imapConnection.createFolderNamed(pEpFolderName)
    }

    private func createPepFolderName(for cdAccount: CdAccount) -> String? {
        guard
            let seperator = CdFolder.folderSeparatorAsString(cdAccount: cdAccount),
            let inbox = CdFolder.by(folderType: .inbox, account: cdAccount, context: privateMOC),
            let inboxName = inbox.name
            else {
                handle(error: BackgroundError.ImapError.invalidAccount)
                return nil
        }
        let pEpFolderName = inboxName + seperator + CdFolder.pEpSyncFolderName
        return pEpFolderName
    }

    /// Creates local pEpSync folder.
    /// - note: MUST be called on privateMoc
    private func createLocalPEPFolder() {
        guard
            let cdAccount = imapConnection.cdAccount(moc: privateMOC),
            let inbox = CdFolder.by(folderType: .inbox, account: cdAccount, context: privateMOC),
            let seperator = CdFolder.folderSeparatorAsString(cdAccount: cdAccount),
            let name = createPepFolderName(for: cdAccount),
            let localPEPFolder = CdFolder.updateOrCreate(folderName: name,
                                                         folderSeparator: seperator,
                                                         folderType: .pEpSync,
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

extension CreateIMAPPepFolderOperation {

    fileprivate func handleFolderCreateCompleted() {
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.privateMOC.performAndWait {
                me.createLocalPEPFolder()
                me.savecontext()
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

class CreateIMAPPepFolderOperationSyncDelegate: DefaultImapConnectionDelegate {
    override func folderCreateCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? CreateIMAPPepFolderOperation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateCompleted()
    }

    override func folderCreateFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? CreateIMAPPepFolderOperation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateFailed()
    }
}
