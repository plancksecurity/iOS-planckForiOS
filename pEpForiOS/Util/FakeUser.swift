//
//  FakeUser.swift
//  pEp
//
//  Created by Dirk Zimmermann on 07.03.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import PEPObjCAdapterFramework

class FakeUser {
    func some() {
        let ident = PEPIdentity()
        func sorter(_ s1: String, s2: String) -> ComparisonResult {
            return ComparisonResult.orderedSame
        }
        let theSet = SortedSet.init(array: [], sortBlock: sorter)
        _ = Fake.dontMix1(set: theSet)
        _ = Fake.dontMix2(identity: ident)
        _ = Fake.mix(set: theSet, identity: ident)
    }
}
