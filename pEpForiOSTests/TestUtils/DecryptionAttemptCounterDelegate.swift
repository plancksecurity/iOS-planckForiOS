//
//  DecryptionAttemptCounterDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

@testable import pEpForiOS
@testable import MessageModel // Use of MM-internal functionality marked as deprecated.
import PEPObjCAdapterFramework

@available(*, deprecated, message: "Uses MM-internal functionality")
class DecryptionAttemptCounterDelegate: DecryptMessagesOperationDelegateProtocol {
    var numberOfMessageDecryptAttempts = 0

    func decrypted(originalCdMessage: CdMessage, decryptedMessageDict: NSDictionary?,
                   rating: PEPRating, keys: [String]) {
        numberOfMessageDecryptAttempts += 1
    }
}
