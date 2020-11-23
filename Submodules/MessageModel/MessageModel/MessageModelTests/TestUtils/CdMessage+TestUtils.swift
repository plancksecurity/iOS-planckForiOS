//
//  CdMessage+TestUtils.swift
//  pEpForiOS
//
//  Created by buff on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import CoreData
@testable import MessageModel

extension CdMessage {
    func isValidMessage() -> Bool {
        return self.longMessage != nil
            || self.longMessageFormatted != nil
            || self.attachments?.count ?? 0 > 0
            || self.shortMessage != nil
    }

    //???: looks like there are redundant search(..) and by(..) methods in MM, App and AppTest target. Double check, merge.
    public static func search(byUUID uuid: MessageID,
                              includeFakeMessages: Bool,
                              context: NSManagedObjectContext) -> [CdMessage] {
        return by(uuid: uuid, includeFakeMessages: includeFakeMessages, in: context)
    }

    static func by(uuid: MessageID, includeFakeMessages: Bool, in context: NSManagedObjectContext) -> [CdMessage] {
        if includeFakeMessages {
            return CdMessage.all(predicate: NSPredicate(format: "%K = %@", CdMessage.AttributeName.uuid, uuid), in:context)
                as? [CdMessage] ?? []
        } else {
            return CdMessage.all(predicate: NSPredicate(format: "%K = %@ AND %K != %d",
                                                        CdMessage.AttributeName.uuid,
                                                        uuid,
                                                        CdMessage.AttributeName.uid,
                                                        Int32(Message.uidFakeResponsivenes)),
                                 in: context)
                as? [CdMessage] ?? []
        }
    }
}
