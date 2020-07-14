//
//  CDIdentity+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 01.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework
import CoreData

extension CdIdentity {
    /**
     Uses the adapter's update to determine the fingerprint of the given identity.
     */
    func fingerPrint() throws -> String? {//!!!: IOS-2325_!
            let pEpID = pEpIdentity()
            try PEPSession().update(pEpID)//!!!: IOS-2325_!
            return pEpID.fingerPrint
    }

    /**
     Can a meaningful handshake action be invoked on this identity?
     Like trust, mistrust, or reset?
     Currently, you can't reset/undo a mistrust, so it's not included.
     See ENGINE-409, ENGINE-355.
     */
    func canInvokeHandshakeAction() -> Bool {//!!!: IOS-2325_!
        if isMySelf {
            return false
        }
        let color = pEpColor()//!!!: IOS-2325_!
        return color == .yellow || color == .green
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

    //!!!: MUST become internal after tests have been moved
    public static func from(pEpContact: PEPIdentity?,
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

    func pEpRating(pEpSession: PEPSession = PEPSession()) -> PEPRating {//!!!: IOS-2325_!
        return PEPUtils.pEpRating(cdIdentity: self)//!!!: IOS-2325_!
    }

    func pEpColor(pEpSession: PEPSession = PEPSession()) -> PEPColor {//!!!: IOS-2325_!
        return PEPUtils.pEpColor(cdIdentity: self)//!!!: IOS-2325_!
    }

//    /// Will use update_identity() for other identities, and myself() for own ones. //BUFF: UNUSED
//    ///
//    /// - Parameter session: pEpsession to work on
//    /// - Returns: A `PEPIdentity` that has been updated and thus should contain the fingerprint.
//    @discardableResult
//    func updatedIdentity(pEpSession: PEPSession = PEPSession()) -> PEPIdentity {//!!!: IOS-2325_! //UNUSED?
//        let md = pEpIdentity()
//        do {
//            if md.isOwn {
//                try pEpSession.mySelf(md)//!!!: IOS-2325_!
//            } else {
//                try pEpSession.update(md)//!!!: IOS-2325_!
//            }
//        } catch {
//            Log.shared.errorAndCrash("%@", error.localizedDescription)
//        }
//        return md
//    }
}
