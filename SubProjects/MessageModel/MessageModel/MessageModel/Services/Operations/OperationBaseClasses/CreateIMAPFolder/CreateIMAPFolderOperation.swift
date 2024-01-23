//
//  CreateIMAPFolderOperation.swift
//  MessageModel
//
//  Created by Martin Brude on 22/1/24.
//  Copyright © 2024 planck Security S.A. All rights reserved.
//

import Foundation
import CoreData

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

class CreateIMAPFolderOperation: ImapSyncOperation {

    private var saveContextWhenDone: Bool
    public private(set) var folderType: FolderType
    private weak var delegate: CreateIMAPPlanckFolderOperationSyncDelegate?

    init(parentName: String,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         saveContextWhenDone: Bool = true,
         folderType: FolderType) {
        self.saveContextWhenDone = saveContextWhenDone
        self.folderType = folderType
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
    
    // Indicates whether a folder of the specified operation type exists locally in the given account
    public func folderExists(for cdAccount: CdAccount) -> Bool {
        return CdFolder.by(folderType: folderType, account: cdAccount, context: privateMOC) != nil
    }

    public func createFolder(for cdAccount: CdAccount) {
        guard let folderName = createPlanckFolderName(for: cdAccount) else {
            handle(error: BackgroundError.ImapError.invalidAccount)
            return
        }
        imapConnection.createFolderNamed(folderName)
    }

    /// Creates a local folder.
    /// - note: MUST be called on privateMoc
    public func createLocalPlanckFolder() {
        guard
            let cdAccount = imapConnection.cdAccount(moc: privateMOC),
            let inbox = CdFolder.by(folderType: .inbox, account: cdAccount, context: privateMOC),
            let seperator = CdFolder.folderSeparatorAsString(cdAccount: cdAccount),
            let name = createPlanckFolderName(for: cdAccount),
            let localPlanckFolder = CdFolder.updateOrCreate(folderName: name,
                                                         folderSeparator: seperator,
                                                         folderType: folderType,
                                                         account: cdAccount,
                                                         context: privateMOC)
            else {
                handle(error: BackgroundError.ImapError.invalidAccount)
                return
        }
        localPlanckFolder.parent = inbox
    }

    public func createPlanckFolderName(for cdAccount: CdAccount) -> String? {
        guard
            let seperator = CdFolder.folderSeparatorAsString(cdAccount: cdAccount),
            let inbox = CdFolder.by(folderType: .inbox, account: cdAccount, context: privateMOC),
            let inboxName = inbox.name
            else {
                handle(error: BackgroundError.ImapError.invalidAccount)
                return nil
        }
        let lastPart = folderType == .pEpSync ? CdFolder.planckSyncFolderName : CdFolder.planckSuspiciousFolderName
        let planckFolderName = inboxName + seperator + lastPart
        return planckFolderName
    }
    
    public func saveContext() {
        if saveContextWhenDone {
            privateMOC.saveAndLogErrors()
        }
    }
    
    // MARK: - Must subclass

    public func createSyncDelegate() -> ImapConnectionDelegate {
        return CreateIMAPPlanckFolderOperationSyncDelegate(errorHandler: self)
    }
}

// MARK: - Callbacks

extension CreateIMAPFolderOperation {

    public func handleFolderCreateCompleted() {
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

    public func handleFolderCreateFailed() {
        // The server refused to let us create a folder. That can happen. GMX free accounts for
        // instance allow 10 custom folders only.
        // We silently ignore those errors.
        waitForBackgroundTasksAndFinish()
    }
}

// MARK: - Private

extension CreateIMAPFolderOperation {

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
}
