//
//  ServerCredentials+KeyChain.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.12.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

extension ServerCredentials {
    /// Fixes the case where after a restore from a backup, key chain passwords are lost,
    /// as seen in IOS-2932/PEMA-134.
    public func fixLostPassword() {
        cdObject.fixLostPassword()
    }
}
