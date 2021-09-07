//
//  CDIdentity+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 01.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

extension CdIdentity {
    func fingerprint(completion: @escaping (String?) -> ()) {
        let pEpID = pEpIdentity()
        PEPSession().update(pEpID,
                                 errorCallback: { _ in
                                    completion(nil)
        }) { updatedIdentity in
            completion(updatedIdentity.fingerPrint)
        }
    }

    /**
     Can a meaningful handshake action be invoked on this identity?
     Like trust, mistrust, or reset?
     Currently, you can't reset/undo a mistrust, so it's not included.
     See ENGINE-409, ENGINE-355.
     */
    func canInvokeHandshakeAction(completion: @escaping (Bool)->Void) {
        managedObjectContext?.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            if me.isMySelf {
                completion(false)
                return
            }
            me.pEpColor { (color) in
                completion(color == .yellow || color == .green)
            }
        }
    }

    /**
     Converts a `CdIdentity` to a pEp contact (`PEPId`).
     - Parameter cdIdentity: The core data contact object.
     - Returns: An `PEPIdentity` contact for pEp.
     */
    func pEpIdentity() -> PEPIdentity {
        guard let address = address else {
            Log.shared.errorAndCrash("missing address: %@", self)
            return PEPIdentity(address: "none")
        }
        return PEPIdentity(address: address,
                           userID: userID,
                           userName: userName,
                           isOwn: isMySelf,
                           fingerPrint: nil,
                           commType: PEPCommType.unknown,
                           language: nil)
    }

    static func from(pEpContact: PEPIdentity?,
                     context: NSManagedObjectContext) -> CdIdentity? {
        guard let pEpC = pEpContact else {
            return nil
        }
        var identity: CdIdentity
        if let existing = CdIdentity.search(address: pEpC.address, context: context){
            identity = existing
            if !identity.isMySelf {
                identity.userName = pEpC.userName
            }
        } else {
            // this identity has to be created
            identity = CdIdentity.updateOrCreate(withAddress: pEpC.address,
                                                 userID: pEpC.userID,
                                                 userName: pEpC.userName,
                                                 context: context)
        }

        return identity
    }

    static func from(pEpContacts: [PEPIdentity]?,
                     context: NSManagedObjectContext) -> [CdIdentity] {
        let theContacts = pEpContacts ?? []
        var contacts = [CdIdentity]()
        for p in theContacts {
            if let c = from(pEpContact: p, context: context) {
                contacts.append(c)
            }
        }
        return contacts
    }

    func pEpRating(completion: @escaping (PEPRating) -> Void) {
        PEPUtils.pEpRating(cdIdentity: self) { rating in
            completion(rating.pEpRating())
        }
    }

    func pEpColor(context: NSManagedObjectContext = Stack.shared.mainContext,
                  completion: @escaping (PEPColor) -> Void) {
        PEPUtils.pEpColor(cdIdentity: self, context: context, completion: completion)
    }

    /// Converts a typical core data set of CdIdentities into pEp identities.
    static func pEpIdentities(cdIdentitiesSet: NSOrderedSet?) -> [PEPIdentity]? {
        guard let cdIdentities = cdIdentitiesSet?.array as? [CdIdentity] else {
            return nil
        }
        return cdIdentities.map {
            return $0.pEpIdentity()
        }
    }
}
