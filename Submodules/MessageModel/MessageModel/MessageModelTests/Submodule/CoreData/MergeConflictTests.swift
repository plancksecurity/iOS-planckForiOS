//
//  MergeConflictTests.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.06.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData
import Foundation

@testable import MessageModel

class MergeConflictTests: PersistentStoreDrivenTestBase {
    var backgroundMOC: NSManagedObjectContext!

    let originalPepRating: Int16 = 5
    let changedPepRating: Int16 = 6
    let msgUID: UInt = 555
    var msgUUID = MessageID.generateUUID()
    var cdMsg: CdMessage!

    override func setUp() {
        super.setUp()
        backgroundMOC = Stack.shared.newPrivateConcurrentContext

        let messageBuilder = Message.fakeMessage(uuid: msgUUID, uid: 0)
        messageBuilder.imapFlags.seen = true
        cdMsg = messageBuilder.cdObject
        cdAccount = messageBuilder.parent.account.cdObject
        cdMsg.pEpRating = originalPepRating
        cdMsg.uid = Int32(msgUID)
        cdMsg.uuid = msgUUID

        messageBuilder.save()
    }

    func testPotentialMergeConflict() {
        let context1: NSManagedObjectContext = moc
        let context2: NSManagedObjectContext = backgroundMOC

        let maxCount = 1000
        let expFinished1 = expectation(description: "expFinished1")
        let expFinished2 = expectation(description: "expFinished2")

        context1.perform {
            guard let cdMsg = context1.object(with: self.cdMsg.objectID) as? CdMessage else {
                XCTFail()
                return
            }
            for _ in 0..<maxCount {
                XCTAssertNotNil(cdMsg)
                if cdMsg.pEpRating == self.changedPepRating {
                    cdMsg.pEpRating = self.originalPepRating
                    XCTAssertEqual(cdMsg.pEpRating, self.originalPepRating)
                } else {
                    cdMsg.pEpRating = self.changedPepRating
                    XCTAssertEqual(cdMsg.pEpRating, self.changedPepRating)
                }
                context1.saveAndLogErrors()
            }
            expFinished1.fulfill()
        }
        context2.perform {
            guard let cdMsg = context2.object(with: self.cdMsg.objectID) as? CdMessage
                else {
                    XCTFail()
                    return
            }
            for _ in 0..<maxCount {
                XCTAssertNotNil(cdMsg)
                if cdMsg.imap?.serverFlags?.flagSeen == false {
                    cdMsg.imap?.serverFlags?.flagSeen = true
                    XCTAssertEqual(cdMsg.imap?.serverFlags?.flagSeen, true)
                } else {
                    cdMsg.imap?.serverFlags?.flagSeen = false
                    XCTAssertEqual(cdMsg.imap?.serverFlags?.flagSeen, false)
                }
                context2.saveAndLogErrors()
            }
            expFinished2.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    //!!!: all the below potentially fails randomly as contexts are merged asynchronously in Stack. RM. all below after Stack is in desired state
    // MARK: - Changes from context to contex

    func testChangeInbackgroundMOC_doesNotAlterMainContextWhithoutSaving() {
        var cdMsgBackground1: CdMessage?
        backgroundMOC.performAndWait {
            cdMsgBackground1 = CdMessage.by(uuid: msgUUID,
                                            uid: msgUID,
                                            account: cdAccount,
                                            context: backgroundMOC)
        }

        guard
            let cdMsg = CdMessage.by(uuid: msgUUID,
                                     uid: msgUID,
                                     account: cdAccount,
                                     context: moc),
            let cdMsg1 = cdMsgBackground1
            else {
                XCTFail()
                return
        }

        var backgroundRating: Int16? = nil
        var backgroundFlagSeen: Bool?
        backgroundMOC.performAndWait {
            cdMsg1.pEpRating = changedPepRating
            XCTAssertEqual(cdMsg1.pEpRating, changedPepRating)
            guard let seen = cdMsg1.imap?.serverFlags?.flagSeen else {
                XCTFail("Problem getting flagSeen")
                return
            }
            let newSeenValue = !seen
            cdMsg1.imap?.serverFlags?.flagSeen = newSeenValue

            backgroundRating = cdMsg1.pEpRating
            backgroundFlagSeen = cdMsg1.imap?.serverFlags?.flagSeen
        }
        // We need to refresh as merging contexts is done asynchronously.
        moc.refreshAllObjects()

        let mainRating = cdMsg.pEpRating
        XCTAssertNotEqual(mainRating, backgroundRating)

        let mainFlagSeen = cdMsg.imap?.serverFlags?.flagSeen
        XCTAssertNotEqual(mainFlagSeen, backgroundFlagSeen)
    }

    func testChangeInbackgroundMOC_doesAlterMainContextWhenSaving() {
        var cdMsgBackground1: CdMessage?
        backgroundMOC.performAndWait {
            cdMsgBackground1 = CdMessage.by(uuid: msgUUID,
                                            uid: msgUID,
                                            account: cdAccount,
                                            context: backgroundMOC)
        }

        guard
            let cdMsg = CdMessage.by(uuid: msgUUID,
                                     uid: msgUID,
                                     account: cdAccount,
                                     context: moc),
            let cdMsg1 = cdMsgBackground1
            else {
                XCTFail()
                return
        }

        var backgroundRating: Int16? = nil
        var backgroundFlagSeen: Bool?
        backgroundMOC.performAndWait {
            cdMsg1.pEpRating = changedPepRating
            XCTAssertEqual(cdMsg1.pEpRating, changedPepRating)
            guard let seen = cdMsg1.imap?.serverFlags?.flagSeen else {
                XCTFail("Problem getting flagSeen")
                return
            }
            let newSeenValue = !seen
            cdMsg1.imap?.serverFlags?.flagSeen = newSeenValue

            backgroundMOC.saveAndLogErrors()

            backgroundRating = cdMsg1.pEpRating
            backgroundFlagSeen = cdMsg1.imap?.serverFlags?.flagSeen
        }

        // We need to refresh as merging contexts is done asynchronously.
        moc.refreshAllObjects()

        let mainRating = cdMsg.pEpRating
        XCTAssertEqual(mainRating, backgroundRating)

        let mainFlagSeen = cdMsg.imap?.serverFlags?.flagSeen
        XCTAssertEqual(mainFlagSeen, backgroundFlagSeen)
    }

    func testChangeOnmoc_doesNotAlterbackgroundMOCWithoutSaving() {
        var cdMsgBackground1: CdMessage?
        backgroundMOC.performAndWait {
            cdMsgBackground1 = CdMessage.by(uuid: msgUUID,
                                            uid: msgUID,
                                            account: cdAccount,
                                            context: backgroundMOC)
        }

        guard
            let cdMsg = CdMessage.by(uuid: msgUUID,
                                     uid: msgUID,
                                     account: cdAccount,
                                     context: moc),
            let cdMsg1 = cdMsgBackground1
            else {
                XCTFail()
                return
        }
        cdMsg.pEpRating = changedPepRating
        XCTAssertEqual(cdMsg.pEpRating, changedPepRating)
        guard let seen = cdMsg.imap?.serverFlags?.flagSeen else {
            XCTFail("Problem getting flagSeen")
            return
        }
        let newSeenValue = !seen
        cdMsg.imap?.serverFlags?.flagSeen = newSeenValue

        backgroundMOC.performAndWait {
            // We need to refresh as merging contexts is done asynchronously.
            backgroundMOC.refreshAllObjects()
            XCTAssertNotEqual(cdMsg.pEpRating, cdMsg1.pEpRating)
            XCTAssertNotEqual(cdMsg.imap?.serverFlags?.flagSeen,
                              cdMsg1.imap?.serverFlags?.flagSeen)
        }
    }

    func testChangeOnmoc_doesAlterbackgroundMOCWhenSaving() {
        var cdMsgBackground1: CdMessage?
        let moc: NSManagedObjectContext = Stack.shared.mainContext
        let backgroundMOC: NSManagedObjectContext = Stack.shared.newPrivateConcurrentContext
        backgroundMOC.performAndWait {
            cdMsgBackground1 = CdMessage.by(uuid: msgUUID,
                                            uid: msgUID,
                                            account: cdAccount,
                                            context: backgroundMOC)
        }

        guard
            let cdMsg = CdMessage.by(uuid: msgUUID,
                                     uid: msgUID,
                                     account: cdAccount,
                                     context: moc),
            let cdMsg1 = cdMsgBackground1
            else {
                XCTFail()
                return
        }
        cdMsg.pEpRating = changedPepRating
        XCTAssertEqual(cdMsg.pEpRating, changedPepRating)
        guard let seen = cdMsg.imap?.serverFlags?.flagSeen else {
            XCTFail("Problem getting flagSeen")
            return
        }
        let newSeenValue = !seen
        cdMsg.imap?.serverFlags?.flagSeen = newSeenValue
        moc.saveAndLogErrors()

        backgroundMOC.performAndWait {
            XCTAssertEqual(cdMsg.pEpRating, cdMsg1.pEpRating)
            XCTAssertEqual(cdMsg.imap?.serverFlags?.flagSeen,
                              cdMsg1.imap?.serverFlags?.flagSeen)
        }
    }

    func testDiffMergeConflict() {
        guard
            let cdMsg = CdMessage.by(uuid: self.msgUUID,
                                     uid: self.msgUID,
                                     account: self.cdAccount,
                                     context: moc)
            else {
                XCTFail()
                return
        }
        let keyPaths = cdMsg.allPropertyNames()

        let dict1 = cdMsg.dictionaryWithValues(forKeys: keyPaths)

        let pEpRatingKeyPath = "pEpRating"
        var dict2 = dict1
        dict2[pEpRatingKeyPath] = NSNumber(integerLiteral: 50)

        let mc1 = NSMergeConflict(source: cdMsg, newVersion: 1, oldVersion: 2,
                                  cachedSnapshot: dict1,
                                  persistedSnapshot: dict2)
        let conflicts1 = mc1.conflictingKeyPaths()
        var pEpRatingKeyPathInConflict = false
        for cv in conflicts1 {
            if cv.keyPath == pEpRatingKeyPath {
                pEpRatingKeyPathInConflict = true
            }
        }
        XCTAssertTrue(pEpRatingKeyPathInConflict)
        XCTAssertFalse(conflicts1.isEmpty)
    }
}
