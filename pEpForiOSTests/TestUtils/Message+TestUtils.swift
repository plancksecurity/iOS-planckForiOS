//
//  Message+TestUtils.swift
//  pEpForiOS
//
//  Created by buff on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

@testable import MessageModel
@testable import pEpForiOS
import PEPObjCAdapterFramework

extension Message {
    func isValidMessage() -> Bool {
        return self.longMessage != nil
            || self.longMessageFormatted != nil
            || self.attachments.count > 0
            || self.shortMessage != nil
    }
}
