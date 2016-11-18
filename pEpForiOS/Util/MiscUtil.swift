//
//  MiscUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

open class MiscUtil {
    open static func optionalHashValue<T: Hashable>(_ someVar: T?) -> Int {
        if let theVar = someVar {
            return theVar.hashValue
        } else {
            return 0
        }
    }

    open static func isNilOrEmptyNSArray(_ array: NSArray?) -> Bool {
        return array == nil || array?.count == 0
    }

    open static func isEmptyString(_ s: String?) -> Bool {
        if s == nil {
            return true
        }
        if s?.characters.count == 0 {
            return true
        }
        return false
    }
}
