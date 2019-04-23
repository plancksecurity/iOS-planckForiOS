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
import pEpIOSToolbox

public protocol VerifiableAccountIMAPDelegate: class {
    func verified(verifier: VerifiableAccountIMAP,
                  basicConnectInfo: BasicConnectInfo,
                  result: Result<Void, Error>)
}

/// Helper for `VerifiableAccount` (verifies IMAP servers).
public class VerifiableAccountIMAP {
    public weak var verifiableAccountDelegate: VerifiableAccountIMAPDelegate?

    private var sync: ImapSync?
    private var syncDelegate: VerifiableAccountSyncDelegate?
    private var basicConnectInfo: BasicConnectInfo?

    /// Tries to verify the given IMAP account.
    public func verify(basicConnectInfo: BasicConnectInfo) {
        self.basicConnectInfo = basicConnectInfo

        let theSyncDelegate = VerifiableAccountSyncDelegate(errorHandler: self)
        syncDelegate = theSyncDelegate

        sync = ImapSync(connectInfo: basicConnectInfo)
        sync?.delegate = syncDelegate
        sync?.start()
    }

    func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        self.sync = nil

        verifiableAccountDelegate?.verified(
            verifier: self,
            basicConnectInfo: BasicConnectInfo.force(basicConnectInfo: basicConnectInfo),
            result: .success(()))
    }
}

extension VerifiableAccountIMAP: ImapSyncDelegateErrorHandlerProtocol {
    public func handle(error: Error) {
        verifiableAccountDelegate?.verified(
            verifier: self,
            basicConnectInfo: BasicConnectInfo.force(basicConnectInfo: basicConnectInfo),
            result: .failure(error))
    }
}

class VerifiableAccountSyncDelegate: DefaultImapSyncDelegate {
    override func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? VerifiableAccountIMAP)?.authenticationCompleted(
            sync, notification: notification)
    }
}
