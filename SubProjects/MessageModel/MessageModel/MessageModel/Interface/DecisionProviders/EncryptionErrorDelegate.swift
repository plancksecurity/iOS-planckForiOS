//
//  EncryptionErrorDelegate.swift
//  MessageModel
//
//  Created by Andreas Buff on 10.05.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

/// Someone who is reponsible to decide what to do in case we can not encrypt due to an Engine error.
/// Send out unencrypted or not?
public protocol EncryptionErrorDelegate: AnyObject {
    typealias SendUnencrypted = Bool

    /// Called to ask for a decision on encrypt errors.
    /// - Parameter completion: must be called with a decision what to do:
    ///                                     a) send out unencryped (true) ...
    ///                                     b) ... or not (false)
    func handleCouldNotEncrypt(completion: @escaping (SendUnencrypted)->())
}
