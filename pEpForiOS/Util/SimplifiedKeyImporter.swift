//
//  SimplifiedKeyImporter.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class SimplifiedKeyImporter {
    let trustedFingerPrint: String

    init(trustedFingerPrint: String) {
        self.trustedFingerPrint = trustedFingerPrint
    }

    public func process(message: PEPMessage, keys: NSArray) {
        if let signingKey = keys.firstObject as? String,
            signingKey == trustedFingerPrint,
            let theAttachments = message.attachments {
            for attachment in theAttachments {
            }
        }
    }
}
