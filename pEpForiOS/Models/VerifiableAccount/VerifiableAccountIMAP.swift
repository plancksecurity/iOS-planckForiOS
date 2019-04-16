//
//  VerifiableAccountIMAP.swift
//  pEp
//
//  Created by Dirk Zimmermann on 16.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import MessageModel

/// Helper for `VerifiableAccount` (verifies IMAP servers).
class VerifiableAccountIMAP {
    public weak var verifiableAccountDelegate: VerifiableAccountDelegate?

    private var sync: ImapSync?
    private var syncDelegate: VerifiableAccountIMAPDelegate?

    /// Tries to verify the given IMAP account.
    public func verify(basicConnectInfo: BasicConnectInfo) {
        let theSyncDelegate = VerifiableAccountIMAPDelegate(errorHandler: self)
        syncDelegate = theSyncDelegate

        sync = ImapSync(connectInfo: basicConnectInfo)
        sync?.start()
    }
}

extension VerifiableAccountIMAP: ImapSyncDelegateErrorHandlerProtocol {
    public func handle(error: Error) {
    }
}

class VerifiableAccountIMAPDelegate: DefaultImapSyncDelegate {
    override func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
    }

    override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
    }

    override func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
    }

    override func idleFinished(_ sync: ImapSync, notification: Notification?) {
    }
}
