//
//  CdMessage+FakeTest.swift
//  MessageModelTests
//
//  Created by Andreas Buff on 23.07.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

import CoreData
@testable import MessageModel

class CdMessage_FakeTest: PersistentStoreDrivenTestBase {

    func testFakeMessageUpdate() {

        let realUid = Int32(666)
        let realUuid = UUID().uuidString
        let origBody = "origBody"

        // Create a fake message that has been deleted by the user
        let savedFakeMsgWithLocallyModifiedFlags = TestUtil.createCdMessage(cdFolder: trash(),
                                                                            moc: moc)
        savedFakeMsgWithLocallyModifiedFlags.uid = Int32(CdMessage.uidFakeResponsivenes)
        savedFakeMsgWithLocallyModifiedFlags.uuid = realUuid
        savedFakeMsgWithLocallyModifiedFlags.imapFields().localFlags?.flagDeleted = true
        savedFakeMsgWithLocallyModifiedFlags.longMessage = origBody

        // Create the real message fetched from server. It might be encrypted using Message 2.0,
        // so the real, inner UUID might differ from the outer messages UUID!
        let realMessageFetchedFromServer = TestUtil.createCdMessage(cdFolder: trash(), moc: moc)

        realMessageFetchedFromServer.uid = realUid
        realMessageFetchedFromServer.uuid = UUID().uuidString
        realMessageFetchedFromServer.longMessage = "outer message or encrypted garbage"


        let result = CdMessage.findAndUpdateFakeMessage(withUuid: realUuid,
                                                        realMessage: realMessageFetchedFromServer,
                                                        context: moc)
        moc.saveAndLogErrors()

        XCTAssertEqual(result, savedFakeMsgWithLocallyModifiedFlags,
                       "Updated fake message is returned")

        XCTAssertTrue(realMessageFetchedFromServer.managedObjectContext == nil,
                      "realMessageIsDeleted")

        XCTAssertEqual(savedFakeMsgWithLocallyModifiedFlags.uid, realUid, "Uid is updated")

        XCTAssertEqual(savedFakeMsgWithLocallyModifiedFlags.longMessage,
                       origBody,
                       "Body is unchanged")

        XCTAssertEqual(savedFakeMsgWithLocallyModifiedFlags.uuid, realUuid, "UUID is unchanged")
    }

}
 // MARK: - HELPER

extension CdMessage_FakeTest {

    private func trash() -> CdFolder {
        let trash = CdFolder.by(folderType: .trash, account: cdAccount) ?? CdFolder(context: moc)
        trash.folderType = .trash
        trash.name = "trash"
        trash.account = cdAccount
        return trash
    }
}
