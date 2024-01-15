//
//  CreatePepIMAPFolderService.swift.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.06.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import CoreData
import PlanckToolbox

/// Makes sure a special pEp folder exists (locally and on server) to store pEp Sync messages in.
/// It runs exactly once runs once for every `start()` call.
class CreatePepIMAPFolderService: OperationBasedService {
    private let usePlanckFolderProvider: UsePlanckFolderProviderProtocol

    required init(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
                  usePlanckFolderProviderProtocol: UsePlanckFolderProviderProtocol) {
        self.usePlanckFolderProvider = usePlanckFolderProviderProtocol
        super.init(useSerialQueue: true, runOnce: true, backgroundTaskManager: backgroundTaskManager)
    }

    override func operations() -> [Operation] {
        guard usePlanckFolderProvider.usePlanckFolder else {
            // we are not supposed to (create and) use pEp folder for sync messages.
            // Nothing to do.
            return []
        }
        var operations = [Operation]()
        let moc = privateMoc
        moc.performAndWait {
            guard let cdAccounts = CdAccount.all(in: moc) as? [CdAccount] else {
                // No accounts exist.
                // Nothing to do
                return
            }

            for cdAccount in cdAccounts {
                guard cdAccount.pEpSyncEnabled else {
                    // We are not supposed to use pEp Sync with this account, thus we must not
                    // create a pEp folder.
                    // Nothing to do
                    continue
                }

                guard let imapConnectInfo = cdAccount.imapConnectInfo else {
                    Log.shared.errorAndCrash("Account without connect info")
                    continue
                }
                let imapConnection = ImapConnection(connectInfo: imapConnectInfo)
                let loginOP = LoginImapOperation(context: moc, imapConnection: imapConnection)
                let fetchFoldersOP = SyncFoldersFromServerOperation(context: moc,
                                                                    imapConnection: imapConnection)

                let createSuspiciousFolderOP = CreateIMAPSuspiciousFolderOperation(context: moc,
                                                                     imapConnection: imapConnection)

                let createPepFolderOP = CreateIMAPPepFolderOperation(context: moc,
                                                                     imapConnection: imapConnection)
                operations.append(loginOP)
                operations.append(fetchFoldersOP)
                operations.append(createSuspiciousFolderOP)
                operations.append(createPepFolderOP)
            }
        }
        return operations
    }
}
