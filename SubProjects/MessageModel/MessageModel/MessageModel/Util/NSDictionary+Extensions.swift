//
//  NSDictionary+Extensions.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21.09.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import Foundation

extension NSDictionary {
    public func diff(otherDict: NSDictionary) {
        for (k1, v1) in self {
            if let dict1 = v1 as? NSDictionary, let dict2 = otherDict[k1] as? NSDictionary {
                dict1.diff(otherDict: dict2)
            } else {
                let v2 = otherDict[k1]
                if !(v1 as AnyObject).isEqual(v2) {
                    print("diff \(k1): \(v1) != \(v2 ?? "nil")")
                }
            }
        }
        for k2 in otherDict.allKeys {
            if self[k2] == nil {
                print("missing: \(k2)")
            }
        }
    }
}
