//
//  Message+MessageIdentitfying.swift
//  pEp
//
//  Created by Dirk Zimmermann on 09.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension Message: MessageIdentitfying {
    var messageIdentifier: MessageID {
        return messageID
    }
}
