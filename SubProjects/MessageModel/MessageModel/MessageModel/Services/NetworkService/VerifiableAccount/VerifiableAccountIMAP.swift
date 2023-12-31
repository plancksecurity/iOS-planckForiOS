//
//  VerifiableAccountIMAP.swift
//  pEp
//
//  Created by Dirk Zimmermann on 16.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

protocol VerifiableAccountIMAPDelegate: AnyObject {
    func verified(verifier: VerifiableAccountIMAP,
                  result: Result<Void, Error>)
}

/// Helper for `VerifiableAccount` (verifies IMAP servers).
class VerifiableAccountIMAP {
    weak var delegate: VerifiableAccountIMAPDelegate?

    private var imapConnection: ImapConnection?
    private var syncDelegate: VerifiableAccountSyncDelegate?

    /// Stops the verification.
    func stop() {
        imapConnection?.close()
    }

    /// Tries to verify the given IMAP account.
    func verify(connectInfo: EmailConnectInfo) {
        let theSyncDelegate = VerifiableAccountSyncDelegate(errorHandler: self)
        syncDelegate = theSyncDelegate

        imapConnection = ImapConnection(connectInfo: connectInfo)
        imapConnection?.delegate = syncDelegate
        imapConnection?.start()
    }

    func authenticationCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        self.imapConnection = nil

        delegate?.verified(
            verifier: self,
            result: .success(()))
    }
}

// Mark: - ImapConnectionDelegateErrorHandlerProtocol

extension VerifiableAccountIMAP: ImapConnectionDelegateErrorHandlerProtocol {
    func handle(error: Error) {
        delegate?.verified(
            verifier: self,
            result: .failure(error))
    }
}

// Mark: - DefaultImapConnectionDelegate

class VerifiableAccountSyncDelegate: DefaultImapConnectionDelegate {
    override func authenticationCompleted(_ imapConection: ImapConnectionProtocol,
                                          notification: Notification?) {
        (errorHandler as? VerifiableAccountIMAP)?.authenticationCompleted(
            imapConection, notification: notification)
    }
}
