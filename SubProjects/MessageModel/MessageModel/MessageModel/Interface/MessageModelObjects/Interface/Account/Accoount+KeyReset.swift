//
//  Accoount+KeyReset.swift
//  MessageModel
//
//  Created by Andreas Buff on 23.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapter_iOS

extension Account {

    /// Reset the key for this account
    ///
    /// - Parameter completion: Called when done, returning success or error.
    ///                         It maybe called on any queue.
    public func resetKeys(completion: ((Result<Void, Error>) -> ())? = nil) {
        let session = Session()
        let safeUser = Identity.makeSafe(user, forSession: session)
        DispatchQueue.global(qos: .utility).async {
            session.performAndWait {
                let pEpIdentity = safeUser.pEpIdentity()
                PEPSession().update(pEpIdentity,
                                    errorCallback: { error in
                                        completion?(.failure(error))
                                    }) { updatedIdentity in
                    PEPSession().keyReset(updatedIdentity,
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

    /// - Parameter completion: Called when done, returning success or error.
    ///                         It maybe called on any queue.
    public static func resetAllOwnKeys(completion: ((Result<Void, Error>) -> ())? = nil) {
        PEPSession().keyResetAllOwnKeys({ (error: Error) in
            completion?(.failure(error))
        }) {
            completion?(.success(()))
        }
    }
}
