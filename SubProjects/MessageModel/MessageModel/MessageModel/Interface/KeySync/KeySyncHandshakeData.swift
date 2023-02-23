//
//  KeySyncHandshakeData.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 23/2/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation

/// All the data needed for key sync handshakes.
public struct KeySyncHandshakeData {
    public let email: String
    public let username: String?
    public let fingerprintLocal: String?
    public let fingerprintOther: String?
    public let isNewGroup: Bool
}
