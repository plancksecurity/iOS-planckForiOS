//
//  CdMessageTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 12.06.18.
//  Copyright © 2018 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel

class CdMessageTest: PersistentStoreDrivenTestBase {
    enum TestBy {
        case date // distinguish by date
        case uid // distinguish by UID (in the same folder)
        case noDateNoUidDifferingFolders // no date, no uid, differing folders
        case noDateNoUidSameFolder // no date, no uid, the same folder
    }

    func testBasicIsEarlierTo(testBy: TestBy) {
        let cdFolder1 = CdFolder(context: moc)
        cdFolder1.name = "whatever1"

        let cdFolder2 = CdFolder(context: moc)
        cdFolder2.name = "whatever2"

        var cdMessagesOriginal = [CdMessage]()
        for i in 1...5 {
            let cdMsg = CdMessage(context: moc)
            switch testBy {
            case .date:
                cdMsg.sent = Date()
            case .uid:
                cdMsg.parent = cdFolder1
                cdMsg.uid = Int32(i)
            case .noDateNoUidDifferingFolders:
                let cdFolder = CdFolder(context: moc)
                cdFolder.name = "random\(i)"
                cdMsg.parent = cdFolder
            case .noDateNoUidSameFolder:
                cdMsg.parent = cdFolder1
            }
            cdMessagesOriginal.append(cdMsg)
        }

        let cdMessagesSorted1 = cdMessagesOriginal.sorted(by: CdMessage.areInIncreasingOrder)
        XCTAssertEqual(cdMessagesOriginal, cdMessagesSorted1)

        // Irreflexivity
        for i in 0..<cdMessagesOriginal.count {
            XCTAssertFalse(CdMessage.areInIncreasingOrder(cdMessagesOriginal[i],
                                                          cdMsg2: cdMessagesOriginal[i]))
        }

        // Transitive comparability
        XCTAssertTrue(CdMessage.areInIncreasingOrder(cdMessagesOriginal[0],
                                                     cdMsg2: cdMessagesOriginal[1]))
        XCTAssertTrue(CdMessage.areInIncreasingOrder(cdMessagesOriginal[1],
                                                     cdMsg2: cdMessagesOriginal[2]))
        XCTAssertTrue(CdMessage.areInIncreasingOrder(cdMessagesOriginal[0],
                                                     cdMsg2: cdMessagesOriginal[2]))
    }

    func testBasicIsEarlierToByDate() {
        testBasicIsEarlierTo(testBy: .date)
    }

    func testBasicIsEarlierToByUid() {
        testBasicIsEarlierTo(testBy: .uid)
    }

    func testBasicIsEarlierToByNoDateNoUidDifferingFolders() {
        testBasicIsEarlierTo(testBy: .noDateNoUidDifferingFolders)
    }

    func testBasicIsEarlierToByNoDateNoUidSameFolder() {
        testBasicIsEarlierTo(testBy: .noDateNoUidSameFolder)
    }
}
