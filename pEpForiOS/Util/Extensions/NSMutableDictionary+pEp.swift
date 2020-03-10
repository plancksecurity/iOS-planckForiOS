//
//  NSMutableDictionary+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension NSMutableDictionary {
    public var isConfirmed: Bool {
        return (commType.rawValue & PEPCommType.confirmed.rawValue) > 0
    }
}
