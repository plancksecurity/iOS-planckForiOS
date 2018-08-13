//
//  MessageIdentitfying.swift
//  pEp
//
//  Created by Dirk Zimmermann on 09.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Something that has a message-id.
 */
public protocol MessageIdentitfying {
    var messageIdentifier: MessageID { get }
}
