//
//  PEPMessage+TestExtension.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 21.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

@testable import pEpForiOS
@testable import MessageModel //FIXME:
import PEPObjCAdapterFramework

extension PEPMessage {
    public func isLikelyPEPEncrypted() -> Bool {
        guard let attachments = attachments else {
            return false
        }
        return attachments.count == 2 &&
            attachments[0].mimeType == MimeTypeUtils.MimeType.pgpEncrypted.rawValue &&
            attachments[1].mimeType == MimeTypeUtils.MimeType.defaultMimeType.rawValue &&
            attachments[1].filename == "file://msg.asc"
    }
}
