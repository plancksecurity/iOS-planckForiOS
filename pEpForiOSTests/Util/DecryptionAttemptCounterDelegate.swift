//
//  DecryptionAttemptCounterDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

@testable import pEpForiOS
@testable import MessageModel

class DecryptionAttemptCounterDelegate: DecryptMessagesOperationProtocol {
    var numberOfMessageDecryptAttempts = 0

    func decrypted(originalCdMessage: CdMessage, decryptedMessageDict: NSDictionary?,
                   rating: PEP_rating, keys: [String]) {
        numberOfMessageDecryptAttempts += 1
    }
}
