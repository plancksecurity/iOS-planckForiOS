//
//  Message+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension Message {
    var pEpRating: PEP_rating? {
        get {
            return PEPUtil.pEpRatingFromInt(pEpRatingInt)
        }
        set {
            if let nv = newValue {
                pEpRatingInt = Int(nv.rawValue)
            } else {
                pEpRatingInt = nil
            }
        }
    }
}
