//
//  Account+KeySync.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 29/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework

// MARK: - KeySync

extension Account {
    public func isKeySyncEnabled() throws -> Bool {
        return try cdObject.isKeySyncEnabled()
    }

    public func setKeySyncEnabled(enable: Bool) throws {
        try cdObject.setKeySyncEnabled(enable: enable)
    }

    /// Reset the key for this account
    ///
    /// Note: this is an expensive task, the key reset will be done in global queue.
    ///
    /// - Throws: error if something goes wrong
    public func resetKeys(completion: ((Result<Void, Error>) -> ())? = nil) {
        let session = Session()
        let safeUser = Identity.makeSafe(user, forSession: session)
        DispatchQueue.global(qos: .utility).async {
            session.performAndWait {
                let pEpIdentity = safeUser.pEpIdentity()
                let pEpSession = PEPSession()
                do {
                    try pEpSession.update(pEpIdentity)
                    try pEpSession.keyReset(pEpIdentity, fingerprint: pEpIdentity.fingerPrint)
                    completion?(.success(()))
                } catch {
                    completion?(.failure(error))
                }
            }
        }
    }

    public static func resetAllOwnKeys(completion: ((Result<Void, Error>) -> ())? = nil) {
        DispatchQueue.global(qos: .utility).async {
            let session = PEPSession()
            do {
                try session.keyResetAllOwnKeysError()
                completion?(.success(()))
            } catch {
                completion?(.failure(error))
            }
        }
    }
}
