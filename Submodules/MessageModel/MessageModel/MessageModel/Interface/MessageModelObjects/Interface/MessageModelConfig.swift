//
//  MessageModelConfig.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 20.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

public class MessageModelConfig {
    static public func setUnEncryptedSubjectEnabled(_ enabled: Bool) {
        PEPObjCAdapter.setUnEncryptedSubjectEnabled(enabled)
    }

    static public func setPassiveModeEnabled(_ enabled: Bool) {
        PEPObjCAdapter.setPassiveModeEnabled(enabled)
    }
}
