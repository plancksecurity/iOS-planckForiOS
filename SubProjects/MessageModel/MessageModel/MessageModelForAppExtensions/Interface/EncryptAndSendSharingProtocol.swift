//
//  EncryptAndSendSharingProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

/// Contains the method that a sharing extension can use to immediately send
/// the message with the attachments the user wants to share by mail.
public protocol EncryptAndSendSharingProtocol {
    /// Tries to send the given message directly, invoking the
    /// completion block thereafter. There may be errors.
    func send(message: Message, completion: @escaping (Error?) -> ())
}
