
//
//  CdMessage+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdMessage {
    public func updateKeyList(keys: [String]) {
        if !keys.isEmpty {
            self.keysFromDecryption = NSOrderedSet(array: keys.map {
                return CdKey.create(stringKey: $0)
            })
        } else {
            self.keysFromDecryption = nil
        }
    }
}
