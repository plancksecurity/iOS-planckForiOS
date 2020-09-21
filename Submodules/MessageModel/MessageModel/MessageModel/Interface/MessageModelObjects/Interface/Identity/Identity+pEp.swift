//
//  Identity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

extension Identity {
    public func pEpRating(completion: @escaping (Rating) -> Void) {
        cdObject.pEpRating() { pEpRating in
            completion(Rating(pEpRating: pEpRating))
        }
    }

    public func pEpColor(session: Session = Session.main,
                         completion: @escaping (Color) -> Void) {
        cdObject.pEpColor(context: session.moc) {pEpColor in
            completion(Color(pEpColor: pEpColor))
        }
    }
}
