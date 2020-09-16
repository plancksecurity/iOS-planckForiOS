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

    public func pEpRating(completion: @escaping (PEPRating)->Void) {
        cdObject.pEpRating(completion: completion)
    }

    public func pEpIdentity() -> PEPIdentity { //BUFF: bad
        return  cdObject.pEpIdentity()
    }

    public func pEpColor(session: Session = Session.main,
                         completion: @escaping (PEPColor)->Void) {
        cdObject.pEpColor(context: session.moc, completion: completion)
    }
}
