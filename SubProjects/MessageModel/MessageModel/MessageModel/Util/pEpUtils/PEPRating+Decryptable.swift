//
//  PEPRating+Decryptable.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

// MARK: - PEPRating+Decryptable

extension PEPRating {

    /// Whether or not the message could not yet be decrypted
    func isUnDecryptable() -> Bool {
        return PEPRating.undecryptableRatings.contains(self)
    }
}
