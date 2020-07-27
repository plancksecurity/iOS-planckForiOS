//
//  Identity+ResetTrust.swift
//  MessageModel
//
//  Created by Xavier Algarra on 25/09/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework

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
    public func resetTrust(completion: @escaping () -> ()) {//!!!: IOS-2325_!
        func logError() {
            Log.shared.info("User has choosen to rest trust for an identity we have no key for. Valid case, just for the record. The identity is: %@", self.debugDescription)
        }

        let sesion = PEPSession()
        let pEpIdent = pEpIdentity()
        do {
            try sesion.update(pEpIdent)//!!!: IOS-2325_!
            if let _ = pEpIdent.fingerPrint {
                PEPAsyncSession().keyReset(pEpIdent,
                                           fingerprint: fingerprint,
                                           errorCallback: { (_) in
                                            logError()
                }) {
                    completion()
                }
            }
        } catch {
            logError()
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
