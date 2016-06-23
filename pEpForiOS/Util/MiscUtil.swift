//
//  MiscUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

public func optionalHashValue<T: Hashable>(someVar: T?) -> Int {
    if let theVar = someVar {
        return theVar.hashValue
    } else {
        return 0
    }
}