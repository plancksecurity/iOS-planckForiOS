//
//  Identity+ResetTrust.swift
//  MessageModel
//
//  Created by Xavier Algarra on 25/09/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework
import pEpIOSToolbox

extension Identity {

    /// It reset trust for all identities with the same UserID as the identity in the parameter
    ///
    /// - Parameter identityToResetTrust: base identity to reset trust and find other identities with the same userID
    public static func resetTrustAllIdentities(for identityToResetTrust: Identity,
                                               completion: @escaping () -> ()) {
        let identities = identityToResetTrust.allIdentitiesWithTheSameUserID()
        for identity in identities {
            identity.resetTrust(completion: completion)
        }
    }

    /// Reset trust for the identity
    public func resetTrust(completion: @escaping () -> ()) {
        func logError() {
            Log.shared.info("User has choosen to rest trust for an identity we have no key for. Valid case, just for the record.")
        }

        let pEpIdent = pEpIdentity()

        PEPAsyncSession().update(pEpIdent, errorCallback: { _ in
            logError()
            completion()
        }) { updatedIdentity in
            guard let updatedFingerprint = updatedIdentity.fingerPrint else {
                // Valid case. After mistrusting the key of a identity FPR is `nil`
                completion()
                return
            }
            PEPAsyncSession().keyReset(updatedIdentity,
                                       fingerprint: updatedFingerprint,
                                       errorCallback: { (_) in
                                        logError()
                                        completion()
            }) {
                completion()
            }
        }
    }

    /// It indicates if there are other identities with the same usereID
    ///
    /// - Returns: Bool that indicates if there are related identities
    public func userHasMoreThenOneIdentity() -> Bool {

        if allIdentitiesWithTheSameUserID().count > 1{
            return true
        }
        return false
    }

    private func allIdentitiesWithTheSameUserID() -> [Identity] {
        let predicate = CdIdentity.PredicateFactory.sameUserID(value: userID)
        guard let cdidentites = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity]  else {
            Log.shared.errorAndCrash(message: "No identities found!!!")
            return []
        }
        let ids = cdidentites.compactMap { MessageModelObjectUtils.getIdentity(fromCdIdentity: $0) }
        return ids
    }
}
