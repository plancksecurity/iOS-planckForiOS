//
//  FakeMessageTests.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 08.01.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class FakeMessageTests: CoreDataDrivenTestBase {

    override func setUp() {
        super.setUp()
        cdAccount.createRequiredFoldersAndWait(testCase: self)
    }

    func testFakeMsgIsShownInAllFolderTypes() {
        for folderTpe in FolderType.allCases {
            deleteAllMessages()

            guard
                let folder = assureCleanFolderContainingExactlyOneFakeMessage(folderType: folderTpe),
                let allCdMesgs = CdMessage.all() as? [CdMessage] else {
                return
            }
            XCTAssertEqual(allCdMesgs.count, 1, "Exactly one faked message exists in CD")
            let all = folder.allMessages()
            XCTAssertEqual(all.count, 1, "Fake message is shown")
            guard let testee = all.first else {
                XCTFail()
                return
            }
            XCTAssertEqual(testee.uid, Message.uidFakeResponsivenes, "fake message is contained")
        }
    }

    // MARK: - Helper

    private func assureCleanFolderContainingExactlyOneFakeMessage(folderType: FolderType) -> Folder? {
        guard let folder = Folder.by(account: account, folderType: folderType) else {
            return nil
        }
        deleteAllMessages(in: folder)
        createFakeMessage(in: folder)
        simulateSeenByEngine(forAllMessagesIn: folder)
        return folder
    }

    private func createFakeMessage(in folder: Folder) {
        Message(uuid: UUID().uuidString + #function, parentFolder: folder).saveFakeMessage(in: folder)
    }

    private func deleteAllMessages() {
        let moc = Record.Context.main
        moc.performAndWait {
            guard let allCdMesgs = CdMessage.all() as? [CdMessage] else {
                return
            }
            for cdMsg in allCdMesgs {
                moc.delete(cdMsg)
            }
        }
        do {
            try moc.save()
        } catch {
            XCTFail()
        }
    }

    private func deleteAllMessages(in folder: Folder) {
        let moc = Record.Context.main
        moc.performAndWait {
            guard let cdFolder = folder.cdFolder() else {
                XCTFail()
                return
            }
            let allCdMessages = cdFolder.allMessages()
            for cdMsg in allCdMessages {
                moc.delete(cdMsg)
            }
        }
        do {
            try moc.save()
        } catch {
            XCTFail()
        }
    }

    private func simulateSeenByEngine(forAllMessagesIn folder: Folder) {
        let moc = Record.Context.main
        moc.performAndWait {
            guard let cdFolder = folder.cdFolder() else {
                XCTFail()
                return
            }
            let allCdMessages = cdFolder.allMessages()
            for cdMsg in allCdMessages {
                cdMsg.pEpRating = Int16(PEP_rating_trusted.rawValue)
            }
        }
        do {
            try moc.save()
        } catch {
            XCTFail()
        }
    }
}
