//
//  PEPRating+Hashable.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 17/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

/**
 Simple `Hashable` implementation so PEPRating can be put into dictionaries.
 */
extension PEPRating: Hashable {
    public var hashValue: Int {
        return Int(rawValue)
    }
}
