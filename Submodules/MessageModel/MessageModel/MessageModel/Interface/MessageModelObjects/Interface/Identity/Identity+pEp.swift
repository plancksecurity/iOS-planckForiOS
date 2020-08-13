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
    public func pEpRating(completion: @escaping (Rating) -> Void) {
        cdObject.pEpRating() { pEpRating in
            let rating = Rating.from(pEpRating: pEpRating)
            completion(rating)
        }
    }

    public func pEpColor(session: Session = Session.main,
                         completion: @escaping (Color) -> Void) {
        cdObject.pEpColor(context: session.moc) {pEpColor in
            completion(Color.from(pEpColor: pEpColor))
        }
    }
}
