//!!!: crash saving NSValidationErrorKey=serverFlags,
////
////  Message+FakeMessageTest.swift
////  pEpForiOSTests
////
////  Created by Andreas Buff on 08.01.19.
////  Copyright © 2019 p≡p Security S.A. All rights reserved.
////
//
//
//import XCTest
//
////@testable import pEpForiOS
//@testable import MessageModel
//import PEPObjCAdapterFramework
//
//class Message_FakeMessageTest: CoreDataDrivenTestBase {
//    let testUuid = UUID().uuidString + #file
//
//    override func setUp() {
//        super.setUp()
//        cdAccount.createRequiredFoldersAndWait(testCase: self)
//        deleteAllMessages()
//    }
//
//    // MARK: - Fake messages are shown
//
//    func testFakeMsgIsShownInAllFolderTypes() {
//        for folderTpe in FolderType.allCases {
//            deleteAllMessages()
//
//            guard
//                let folder = assureCleanFolderContainingExactlyOneFakeMessage(folderType: folderTpe),
//                let allCdMesgs = CdMessage.all() as? [CdMessage] else {
//                    // That is a valid case. E.g. folderType .normal.
//                    return
//            }
//            XCTAssertEqual(allCdMesgs.count, 1, "Exactly one faked message exists in CD")
//            let all = folder.allMessagesNonThreaded()
//            XCTAssertEqual(all.count, 1, "Fake message is shown")
//            guard let testee = all.first else {
//                XCTFail()
//                return
//            }
//            XCTAssertEqual(testee.uid, Message.uidFakeResponsivenes, "fake message is contained")
//        }
//    }
//
//    // MARK: - isFakeMessage
//
//    func testIsFakeMessage() {
//        for folderTpe in FolderType.allCases {
//            deleteAllMessages()
//            guard
//                let folder = assureCleanFolderContainingExactlyOneFakeMessage(folderType: folderTpe)
//                else {
//                    return
//            }
//            let all = folder.allMessagesNonThreaded()
//            guard let testee = all.first else {
//                XCTFail()
//                return
//            }
//            XCTAssertTrue(testee.isFakeMessage,
//                          "All fake messages in all folder types MUST be recognized")
//        }
//    }
//
//    // MARK: - saveForAppend
//
//    func testSaveForAppend() {
//        for folderType in FolderType.allCases {
//            if folderType.isLocalFolder || !FolderType.requiredTypes.contains(folderType) {
//                continue
//            }
//            deleteAllMessages()
//            guard let folder = Folder.by(account: account, folderType: folderType) else {
//                XCTFail()
//                return
//            }
//            let msg = Message(uuid: testUuid, parentFolder: folder)
//            msg.from = account.user
//            Message.saveForAppend(msg: msg)
//            assureMessageToAppendExistence(in: folder)
//            assureFakeMessageExistence(in: folder)
//        }
//    }
//
//    // MARK: - createCdFakeMessage
//
//    func testCreateCdFakeMessage() {
//        let folderType = FolderType.inbox
//        guard let folder = Folder.by(account: account, folderType: folderType) else {
//            XCTFail()
//            return
//        }
//        let msg = Message(uuid: testUuid, parentFolder: folder)
//        msg.from = account.user
////        Message.createCdFakeMessage(for: msg)
//        assureFakeMessageExistence(in: folder)
//    }
//
//    // MARK: - saveFakeMessage
//
//    func testSaveFakeMessage() {
//        let folderType = FolderType.inbox
//        guard let folder = Folder.by(account: account, folderType: folderType) else {
//            XCTFail()
//            return
//        }
//        let msg = Message(uuid: testUuid, parentFolder: folder)
//        msg.from = account.user
//        msg.saveFakeMessage(in: folder)
//        assureFakeMessageExistence(in: folder)
//    }
//
//    // MARK: - findAndDeleteFakeMessage
//
//    func testFindAndDeleteFakeMessage() {
//        let folderType = FolderType.inbox
//        guard let folder = Folder.by(account: account, folderType: folderType) else {
//            XCTFail()
//            return
//        }
//        let msg = Message(uuid: testUuid, parentFolder: folder)
//        msg.from = account.user
//        msg.saveFakeMessage(in: folder)
//        guard let fakeMsg = assureFakeMessageExistence(mustExist: true, in: folder) else {
//            XCTFail()
//            return
//        }
//        Message.findAndDeleteFakeMessage(withUuid: fakeMsg.uuid, in: folder)
//        assureFakeMessageExistence(mustExist: false, in: folder)
//    }
//
//    // MARK: - Helper
//
//    @discardableResult private func assureFakeMessageExistence(mustExist: Bool = true, in folder: Folder) -> Message? {
//        return assureMessagesExistence(mustExist: mustExist,
//                                       withUid: Message.uidFakeResponsivenes,
//                                       in: folder)
//    }
//
//    @discardableResult private func assureMessageToAppendExistence(mustExist: Bool = true, in folder: Folder)  -> Message? {
//        return assureMessagesExistence(mustExist: mustExist,
//                                       withUid: Message.uidNeedsAppend,
//                                       in: folder)
//    }
//
//    @discardableResult private func assureMessagesExistence(mustExist: Bool = true,
//                                                            withUid uid: Int,
//                                                            in folder: Folder) -> Message? {
//        var result: Message? = nil
//        let moc = Record.Context.main
//        moc.performAndWait {
//            guard let cdFolder =  folder.cdFolder() else {
//                XCTFail()
//                return
//            }
//            let p  = NSPredicate(format: "%K = %d AND %K = %@",
//                                 CdMessage.AttributeName.uid,
//                                 uid,
//                                 CdMessage.RelationshipName.parent,
//                                 cdFolder)
//            guard
//                let allCdMesgs = CdMessage.all(predicate: p) as? [CdMessage],
//                let msg = allCdMesgs.first?.message()
//                else {
//                    if mustExist {
//                        XCTFail()
//                    }
//                    return
//            }
//            XCTAssertEqual(allCdMesgs.count, 1)
//            result = msg
//        }
//        return result
//    }
//
//    private func createMessage(inFolderOfType type: FolderType) -> Message? {
//        guard let folder = Folder.by(account: account, folderType: type) else {
//            XCTFail()
//            return nil
//        }
//        return Message(uuid: testUuid, parentFolder: folder)
//    }
//
//    private func assureCleanFolderContainingExactlyOneFakeMessage(folderType: FolderType) -> Folder? {
//        guard let folder = Folder.by(account: account, folderType: folderType) else {
//            return nil
//        }
//        deleteAllMessages(in: folder)
//        createFakeMessage(in: folder)
//        simulateSeenByEngine(forAllMessagesIn: folder)
//        return folder
//    }
//
//    private func createFakeMessage(in folder: Folder) {
//        Message(uuid: UUID().uuidString + #function, parentFolder: folder).saveFakeMessage(in: folder)
//    }
//
//    private func deleteAllMessages() {
//        let moc = Record.Context.main
//        moc.performAndWait {
//            guard let allCdMesgs = CdMessage.all() as? [CdMessage] else {
//                return
//            }
//            for cdMsg in allCdMesgs {
//                moc.delete(cdMsg)
//            }
//        }
//        do {
//            try moc.save()
//        } catch {
//            XCTFail()
//        }
//    }
//
//    private func deleteAllMessages(in folder: Folder) {
//        let moc = Record.Context.main
//        moc.performAndWait {
//            guard let cdFolder = folder.cdFolder() else {
//                XCTFail()
//                return
//            }
//            let allCdMessages = cdFolder.allMessages()
//            for cdMsg in allCdMessages {
//                moc.delete(cdMsg)
//            }
//        }
//        do {
//            try moc.save()
//        } catch {
//            XCTFail()
//        }
//    }
//
//    private func simulateSeenByEngine(forAllMessagesIn folder: Folder) {
//        let moc = Record.Context.main
//        moc.performAndWait {
//            guard let cdFolder = folder.cdFolder() else {
//                XCTFail()
//                return
//            }
//            let allCdMessages = cdFolder.allMessages()
//            for cdMsg in allCdMessages {
//                cdMsg.pEpRating = Int16(PEPRating.trusted.rawValue)
//            }
//        }
//        do {
//            try moc.save()
//        } catch {
//            XCTFail()
//        }
//    }
//}
