//
//  BaseImapFolderOperation.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.12.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import pEpIOSToolbox

/// Base for an operation that needs to open an IMAP folder to do its work.
class BaseImapFolderOperation: ImapSyncOperation {
    private var folderToOpen: String

    public init(parentName: String = #function,
                context: NSManagedObjectContext? = nil,
                errorContainer: ErrorContainerProtocol = ErrorPropagator(),
                imapConnection: ImapConnectionProtocol,
                folderName: String = ImapConnection.defaultInboxName) {
        self.folderToOpen = folderName
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    override open func main() {
        if !checkImapSync() {
            waitForBackgroundTasksAndFinish()
            return
        }
        process()
    }

    private func process() {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let account = me.imapConnection.cdAccount(moc: privateMOC) else {
                me.addError(BackgroundError.CoreDataError.couldNotFindAccount(
                    info: me.comp))
                me.waitForBackgroundTasksAndFinish()
                return
            }
            if me.folderToOpen.isInboxFolderName() {
                if let folder = CdFolder.by(folderType: FolderType.inbox,
                                            account: account,
                                            context: me.privateMOC) {
                    me.folderToOpen = folder.nameOrCrash
                }
            }
        }
        syncDelegate = BaseImapFolderOperationDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate

        imapConnection.openMailBox(name: folderToOpen, updateExistsCount: true)
    }

    open override func cancel() {
        imapConnection.cancel()
        super.cancel()
    }

    /// Override this in your derived class.
    func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol) {
        fatalError("must be overridden")
    }
}

// MARK: - DefaultImapSyncDelegate

class BaseImapFolderOperationDelegate: DefaultImapConnectionDelegate {
    public override func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        (errorHandler as? BaseImapFolderOperation)?.folderOpenCompleted(imapConnection)
    }
}
