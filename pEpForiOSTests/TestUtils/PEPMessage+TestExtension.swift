//
//  PEPMessage+TestExtension.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 21.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

@testable import pEpForiOS
@testable import MessageModel

extension PEPMessage {
    public func isLikelyPEPEncrypted() -> Bool {
        let theAttachments = attachments ?? []
        return theAttachments.count == 2 &&
            theAttachments[0].mimeType == "application/pgp-encrypted" &&
            theAttachments[1].mimeType == "application/octet-stream" &&
            theAttachments[1].filename == "file://msg.asc"
    }
}
