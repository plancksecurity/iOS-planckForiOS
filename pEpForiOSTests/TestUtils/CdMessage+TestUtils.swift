//
//  CdMessage+TestUtils.swift
//  pEpForiOS
//
//  Created by buff on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
@testable import pEpForiOS

extension CdMessage {
    func isValidMessage() -> Bool {
        return self.longMessage != nil
            || self.longMessageFormatted != nil
            || self.attachments?.count ?? 0 > 0
            || self.shortMessage != nil
    }

    //???: looks like there are redundant search(..) and by(..) methods in MM, App and AppTest target. Double check, merge.
    public static func search(byUUID uuid: MessageID, includeFakeMessages: Bool) -> [CdMessage] {
        return by(uuid: uuid, includeFakeMessages: includeFakeMessages)
    }

    static func by(uuid: MessageID, includeFakeMessages: Bool) -> [CdMessage] {
        if includeFakeMessages {
            return CdMessage.all(predicate: NSPredicate(format: "uuid = %@", uuid))
                as? [CdMessage] ?? []
        } else {
            return CdMessage.all(predicate: NSPredicate(format: "uuid = %@ AND uid != %d",
                                                        uuid,
                                                        Int32(Message.uidFakeResponsivenes)))
                as? [CdMessage] ?? []
        }
    }
}
