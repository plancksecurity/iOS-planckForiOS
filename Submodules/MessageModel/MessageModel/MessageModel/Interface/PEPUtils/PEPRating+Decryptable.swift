//
//  PEPRating+Decryptable.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

// MARK: - PEPRating+Decryptable

extension PEPRating {

    // Whether or not the message could not yet be decrypted
    public func isUnDecryptable() -> Bool {
        return PEPRating.undecryptableRatings.contains(self)
    }
}
