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

    public func isKeySyncEnabled(errorCallback: @escaping (Error) -> (),
                                 successCallback: @escaping (Bool) -> ()) {
        cdObject.isKeySyncEnabled(errorCallback: errorCallback, successCallback: successCallback)
    }

    public func setKeySyncEnabled(enable: Bool,
                                  errorCallback: @escaping (Error?) -> (),
                                  successCallback: @escaping () -> ()) {
        cdObject.setKeySyncEnabled(enable: enable,
                                   errorCallback: errorCallback,
                                   successCallback: successCallback)
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
                PEPAsyncSession().update(pEpIdentity,
                                         errorCallback: { error in
                                            completion?(.failure(error))
                }) { updatedIdentity in
                    PEPAsyncSession().keyReset(updatedIdentity,
                                               fingerprint: updatedIdentity.fingerPrint,
                                               errorCallback: { (error: Error) in
                                                completion?(.failure(error))
                    }) {
                        completion?(.success(()))
                    }
                }
            }
        }
    }

    public static func resetAllOwnKeys(completion: ((Result<Void, Error>) -> ())? = nil) {
        PEPAsyncSession().keyResetAllOwnKeys({ (error: Error) in
            completion?(.failure(error))
        }) {
            completion?(.success(()))
        }
    }
}
