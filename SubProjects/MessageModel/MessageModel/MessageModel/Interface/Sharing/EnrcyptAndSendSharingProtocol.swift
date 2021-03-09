//
//  EnrcyptAndSendSharingProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

public protocol EnrcyptAndSendSharingProtocol {
    /// Tries to send the given message directly, invoking the
    /// completion block thereafter. There may be errors.
    func send(message: Message, completion: (Error?) -> ())
}
