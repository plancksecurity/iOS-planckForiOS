//
//  CreateIMAPPlanckFolderOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 24.06.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

/// Checks if the planck folder (used for planck Sync messages) exists and tries to create it if it
/// does not.
class CreateIMAPPlanckFolderOperation: CreateIMAPFolderOperation {
    
    override init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         saveContextWhenDone: Bool = true) {
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection,
                   saveContextWhenDone: saveContextWhenDone)
    }

    override func createSyncDelegate() -> ImapConnectionDelegate {
        return CreateIMAPFolderOperationSyncDelegate(operation: self, errorHandler: self)
    }
    
    override func createFolder(for cdAccount: CdAccount) {
        createPlanckFolder(for: cdAccount)
    }

    override func folderExists(for cdAccount: CdAccount) -> Bool {
        return CdFolder.by(folderType: .pEpSync, account: cdAccount, context: privateMOC) != nil
    }

    /// Creates local planckSync folder.
    /// - note: MUST be called on privateMoc
    override func createLocalPlanckFolder() {
        guard
            let cdAccount = imapConnection.cdAccount(moc: privateMOC),
            let inbox = CdFolder.by(folderType: .inbox, account: cdAccount, context: privateMOC),
            let seperator = CdFolder.folderSeparatorAsString(cdAccount: cdAccount),
            let name = createPlanckFolderName(for: cdAccount),
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

extension CreateIMAPPlanckFolderOperation {

    private func createPlanckFolder(for cdAccount: CdAccount) {
        guard let pEpFolderName = createPlanckFolderName(for: cdAccount) else {
                handle(error: BackgroundError.ImapError.invalidAccount)
                return
        }
        imapConnection.createFolderNamed(pEpFolderName)
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
        let pEpFolderName = inboxName + seperator + CdFolder.planckSyncFolderName
        return pEpFolderName
    }
}
