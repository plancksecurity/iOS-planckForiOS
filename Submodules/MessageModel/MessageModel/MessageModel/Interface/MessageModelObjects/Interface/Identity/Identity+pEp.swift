//
//  Identity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

//!!: re-think & cleanup. Imo PEPIdentity should never be used in App. Actually the Adapter should be used at least as little as possible in the app. At least all the functtionallity should be moved to CdIdentity and then being forwarded.

extension Identity {

    public static func from(pEpIdentity: PEPIdentity) -> Identity {
        let id = Identity(address: pEpIdentity.address,
                          userID: pEpIdentity.userID,
                          userName: pEpIdentity.userName)
        return id
    }

    public func pEpRating(pEpSession: PEPSession = PEPSession()) -> PEPRating {//!!!: IOS-2325_!
        return cdObject.pEpRating(pEpSession: pEpSession)//!!!: IOS-2325_!
    }

//    public func canResetTrust() -> Bool {//!!!: IOS-2325_! //BUFF: UNUSED
//        let color = cdObject.pEpColor()//!!!: IOS-2325_!
//        return color == .green || color == PEPColor.red
//    }

//    /// Will use update_identity() for other identities, and myself() for own ones. //BUFF: UNUSED
//    ///
//    /// - Parameter session: session to work on
//    /// - Returns: A `PEPIdentity` that has been updated and thus should contain the fingerprint.
//    @discardableResult
//    public func updatedIdentity(pEpSession: PEPSession = PEPSession()) -> PEPIdentity {//!!!: IOS-2325_!
//        return cdObject.updatedIdentity(pEpSession: pEpSession)//!!!: IOS-2325_!
//    }

    public func pEpIdentity() -> PEPIdentity {
        return  cdObject.pEpIdentity()
    }

    public func pEpColor(pEpSession: PEPSession = PEPSession()) -> PEPColor {//!!!: IOS-2325_!
        return cdObject.pEpColor(pEpSession: pEpSession)//!!!: IOS-2325_!
    }
}
