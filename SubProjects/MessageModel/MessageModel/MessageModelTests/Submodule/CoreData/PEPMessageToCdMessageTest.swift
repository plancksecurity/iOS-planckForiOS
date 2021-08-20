//
//  PEPMessageToCdMessageTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 22.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

class PEPMessageToCdMessageTest: PersistentStoreDrivenTestBase {
    /// Tests the conversion from `PEPMessage` to `CdMessage`.
    func testBasic() {
        let attachmentData = Data(repeating: 5, count: 100)

        let msg = PEPMessageUtil.syncMessage(
            ownAddress: "my_address@example.com", attachmentData: attachmentData)
        let cdMsg = CdMessage.from(pEpMessage: msg, context: moc)

        XCTAssertEqual(cdMsg.shortMessage, msg.shortMessage)
        XCTAssertEqual(cdMsg.longMessage, msg.longMessage)
        XCTAssertEqual(cdMsg.attachments?.count, 1)

        guard let cdAttach = cdMsg.attachments?.firstObject as? CdAttachment else {
            XCTFail()
            return
        }
        XCTAssertEqual(cdAttach.data, attachmentData)
        XCTAssertEqual(Int32(cdAttach.contentDispositionTypeRawValue),
                       PEPContentDisposition.attachment.rawValue)
        XCTAssertEqual(cdAttach.contentDispositionTypeRawValue,
                       Attachment.ContentDispositionType.attachment.rawValue)

        XCTAssertEqual(cdMsg.messageID, msg.messageID)

        // Converts an optional NSOrderedSet to [CdMessageReference].
        func extractReferences(_ fromReferences: NSOrderedSet?) -> [String] {
            let msgRefs = fromReferences?.array as? [CdMessageReference] ?? []
            return msgRefs.compactMap { $0.reference }
        }

        XCTAssertEqual(extractReferences(cdMsg.references), msg.references ?? [])
        XCTAssertEqual(extractReferences(cdMsg.inReplyTo), msg.inReplyTo ?? [])
    }
}
