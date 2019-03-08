//
//  Fake.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 07.03.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

public class Fake {
    public static func dontMix1(set: SortedSet<String>) -> [String] {
        return []
    }

    public static func dontMix2(identity: PEPIdentity) -> [PEPIdentity] {
        return []
    }

    public static func mix(set: SortedSet<String>, identity: PEPIdentity) -> [PEPIdentity] {
        return []
    }
}
