//
//  PEPMessage+TestExtension.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 21.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension PEPMessage {
    public func isLikelyPEPEncrypted() -> Bool {
        guard let attachments = attachments else {
            return false
        }
        return attachments.count == 2 &&
            attachments[0].mimeType == MimeTypeUtils.MimesType.pgpEncrypted &&
            attachments[1].mimeType == MimeTypeUtils.MimesType.defaultMimeType &&
            attachments[1].filename == "file://msg.asc"
    }
}
