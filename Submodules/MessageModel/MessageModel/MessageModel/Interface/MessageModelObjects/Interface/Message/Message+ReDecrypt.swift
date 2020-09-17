//
//  Message+ReDecrypt.swift
//  MessageModel
//
//  Created by Andreas Buff on 24.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

// MARK: - Message+ReDecrypt

extension Message {

    /// Marks the message to redecrypt if it is yet undecryptable.
    /// - returns: Whether or not the message has been marked for redecryption
    @discardableResult
    public func markForRetryDecryptIfUndecryptable() -> Bool {
        return cdObject.markForRetryDecryptIfUndecryptable()
    }
}
