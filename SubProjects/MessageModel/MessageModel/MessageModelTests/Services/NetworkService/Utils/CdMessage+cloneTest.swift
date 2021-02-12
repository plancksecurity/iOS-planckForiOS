//
//  CdMessage+cloneTest.swift
//  MessageModelTests
//
//  Created by Alejandro Gelos on 13/08/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel

final class CdMessage_cloneTest: PersistentStoreDrivenTestBase {

    func testCloneWithZeroUID() {
        // GIVEN

        //Set folder to cdMessage
        let cdMessage = TestUtil.createCdMessage(cdFolder: cdInbox, moc: moc)
        cdMessage.parent = cdInbox

        //Set attachments to cdMessage
        let attachments = TestUtil.createAttachments(numAttachments: Int.random(in: 13...21))
        let cdAttachments = attachments.map { $0.cdObject }
        cdMessage.attachments = NSOrderedSet(array: cdAttachments)

        //Set longMessageFormatted to cdMessage
        let attachmentsFileNames = attachments.compactMap { $0.fileName }
        cdMessage.longMessageFormatted = attachmentsFileNames.reduce("") { $0 + $1.extractFileNameOrCid() }

        moc.saveAndLogErrors()

        //WHEN
        let cloneCdMessage = cdMessage.cloneWithZeroUID(context: moc)
        moc.saveAndLogErrors()
        let cloneAttachmentsFileNames = cloneCdMessage.attachments?.compactMap { ($0 as? CdAttachment)?.fileName }
        let optCloneLongMessageFormatted = cloneAttachmentsFileNames?.reduce("") { $0 + $1.extractFileNameOrCid() }
        guard let cloneLongMessageFormatted = optCloneLongMessageFormatted else {
            XCTFail()
            return
        }

        //THEN
        let actual = State(numAttachments: CdAttachment.all(in: moc)?.count ?? 0,
                       numOfMessages: CdMessage.all(in: moc)?.count ?? 0,
                       longMessageFormatted: cloneCdMessage.longMessageFormatted ?? "fail")

        let expected = State(numAttachments: attachments.count * 2,
                         numOfMessages: 2,
                         longMessageFormatted: cloneLongMessageFormatted)

        assertExpectations(actual: actual, expected: expected)
    }
}

// MARK: - Private

extension CdMessage_cloneTest {
    private func assertExpectations(actual: State?, expected: State?) {
        guard let expected = expected,
            let actual = actual else {
                XCTFail()
                return
        }
        XCTAssertEqual(actual.numAttachments, expected.numAttachments)
        XCTAssertEqual(actual.longMessageFormatted, expected.longMessageFormatted)
        XCTAssertEqual(actual.numOfMessages, expected.numOfMessages)
    }
}

// MARK: - Helper Structs

extension CdMessage_cloneTest {
    struct State: Equatable {
        var numAttachments: Int
        var numOfMessages: Int
        var longMessageFormatted: String

        // Default value are default initial state
        init(numAttachments: Int = 0,
             numOfMessages: Int = 0,
             longMessageFormatted: String = "") {
            self.numAttachments = numAttachments
            self.numOfMessages = numOfMessages
            self.longMessageFormatted = longMessageFormatted
        }
    }
}


