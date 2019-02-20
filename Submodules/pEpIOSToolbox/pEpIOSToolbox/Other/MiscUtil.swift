//
//  MiscUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//
import Foundation

open class MiscUtil {
    public static func optionalHashValue<T: Hashable>(_ someVar: T?) -> Int {
        if let theVar = someVar {
            return theVar.hashValue
        } else {
            return 0
        }
    }

    public static func isNilOrEmptyNSArray(_ array: NSArray?) -> Bool {
        return array == nil || array?.count == 0
    }

    public static func isEmptyString(_ s: String?) -> Bool {
        if s == nil {
            return true
        }
        if s?.count == 0 {
            return true
        }
        return false
    }

    public static func isUnitTest() -> Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
