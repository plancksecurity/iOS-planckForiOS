//
//  FetchMessagesServiceTest.swift
//  MessageModelTests
//
//  Created by Xavier Algarra on 14/08/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
import pEpIOSToolbox

class FetchMessagesServiceTest: PersistentStoreDrivenTestBase {
    var inbox: Folder? {
        return cdAccount.account().firstFolder(ofType: .inbox)
    }

    func testBasicFetchMessages() {

        guard let folder = inbox else {
            XCTFail()
            return
        }
        let fetchComplete = expectation(description: "fetchComplete")
        // Save new message for append
        let messageToAppend = newMessageWithUid0()
        let uuid = messageToAppend?.uuid
        // run sync loop once to append the mail to server
        TestUtil.syncAndWait(testCase: self)
        let cdMessages = CdMessage.all(in: moc)
        // as sync loop also downloads the messages we remove everything in DB
        for message in cdMessages! {
            moc.delete(message)
        }
        moc.saveAndLogErrors()
        let fetchMessagesService = FetchMessagesService()
        // fetch new messages
        do {
            try fetchMessagesService.runService(inFolders: [folder]) {
                fetchComplete.fulfill()
            }
        } catch {
            guard let er = error as? FetchServiceBaseClass.FetchError,
                er != FetchServiceBaseClass.FetchError.isFetching else {
                    Log.shared.errorAndCrash("Unexpected error")
                    return
            }
            // Alredy fetching do nothing
        }
        waitForExpectations(timeout: TestUtil.waitTime)
        let messagesAfterFetch = CdMessage.all(in: moc) as? [CdMessage]
        let downloadedMessage = messagesAfterFetch?.first(where: {$0.uuid == uuid})
        XCTAssertEqual(downloadedMessage?.uuid, uuid, "assure Message with the same UUID is present")
        XCTAssertNotEqual(downloadedMessage?.uid, Int32(CdMessage.uidNeedsAppend), "assure this message has not UID = 0")
    }
}

// MARK: - Helper

extension FetchMessagesServiceTest {

    private func newMessageWithUid0() -> CdMessage? {
        guard let cdFolder = inbox?.cdObject else {
            XCTFail("missing folder")
            return nil
        }
        let message = TestUtil.createCdMessage(cdFolder: cdFolder, moc: moc)
        message.pEpProtected = false
        moc.saveAndLogErrors()
        return message
    }
}
