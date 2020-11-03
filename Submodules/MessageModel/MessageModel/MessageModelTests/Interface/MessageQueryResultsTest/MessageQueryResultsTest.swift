//
//  MessageQueryResultsTest.swift
//  MessageModelTests
//
//  Created by Alejandro Gelos on 22/02/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

import CoreData

@testable import MessageModel
import PEPObjCAdapterFramework

class MessageQueryResultsTest: PersistentStoreDrivenTestBase {
    var messageQueryResults: MessageQueryResults?
    var account1: CdAccount!
    var account2: CdAccount!
    var cdFolder1: CdFolder!

    override func setUp() {
        super.setUp()

        // Account 1 with 0 messages
        account1 = cdAccount
        guard let cdFolder1 = account1.folders?.firstObject as? CdFolder else {
            XCTFail()
            return
        }
        self.cdFolder1 = cdFolder1

        // Account 2 with 50 messages in Inbox
        account2 = TestUtil.createFakeAccount(idAddress: "account2@test.com",
                                              idUserName: "test2",
                                              moc: moc)
        guard let cdFolder2 = account2.folders?.firstObject as? CdFolder else {
            XCTFail()
            return
        }

        createCdMessages(numMessages: 50, cdFolder: cdFolder2, context: moc)

        moc.saveAndLogErrors()
        messageQueryResults = MessageQueryResults(withFolder: cdFolder1.folder())
    }

    override func tearDown() {
        messageQueryResults?.rowDelegate = nil
        messageQueryResults = nil
        super.tearDown()
    }

    func testInit() {
        // Given
        guard let cdFolder1 = cdFolder1 else {
            XCTFail()
            return
        }

        // When
        let messageQueryResults = MessageQueryResults(withFolder: cdFolder1.folder())

        // Then
        XCTAssertNotNil(messageQueryResults)
    }

    func testStartMonitoringWithOutElements() {
        // Given
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }

        // When
        guard let _ = try? messageQueryResults.startMonitoring() else {
            XCTFail()
            return
        }

        // Then
        let expectedMessagesCount = 0
        XCTAssertEqual(try? messageQueryResults.count(), expectedMessagesCount)
    }

    /*
    func testStartMonitoringWithElements() {
        // Given
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }
        createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)

        // When
        guard let _ = try? messageQueryResults.startMonitoring() else {
            XCTFail()
            return
        }

        // Then
        let expectedMessagesCount = 20
        let messagesCount = try! messageQueryResults.count()
        XCTAssertEqual(messagesCount, expectedMessagesCount)
        for i in 1..<messagesCount {
            XCTAssertTrue(type(of: messageQueryResults[i]) == Message.self)
            XCTAssertTrue(messageQueryResults[i-1].sent! > messageQueryResults[i].sent!)
        }
    }

    func testCount() {
        // Given
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }
        let expectedMessagesCount = 20
        createCdMessages(numMessages: expectedMessagesCount, cdFolder: cdFolder1, context: moc)

        // When
        guard let _ = try? messageQueryResults.startMonitoring() else {
            XCTFail()
            return
        }

        // Then

        XCTAssertEqual(try? messageQueryResults.count(), expectedMessagesCount)
    }

    func testSubscript() {
        // Given
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }

        let messages = createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)
        messages[19].shortMessage = "test 0" //Inverted since orderred by date
        messages[10].shortMessage = "test 9"
        messages[0].shortMessage = "test 19"

        // When
        guard let _ = try? messageQueryResults.startMonitoring() else {
            XCTFail()
            return
        }

        // Then
        XCTAssertTrue(type(of: messageQueryResults[0]) == Message.self)
        XCTAssertEqual(messageQueryResults[19].shortMessage, "test 19")
        XCTAssertEqual(messageQueryResults[9].shortMessage, "test 9")
        XCTAssertEqual(messageQueryResults[0].shortMessage, "test 0")
    }

    func testSetFilter() {
        // Given
        let messages = createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)
        messages[0].imapFields().localFlags?.flagFlagged = true
        messages[10].imapFields().localFlags?.flagFlagged = true
        let filter = MessageQueryResultsFilter(mustBeFlagged: true,
                                               mustBeUnread: false,
                                               mustContainAttachments: nil,
                                               accounts: [account1.account()])
        let messageQueryResults = MessageQueryResults(withFolder: cdFolder1.folder(),
                                                      filter: filter)

        // When
        try? messageQueryResults.startMonitoring()

        // Then
        let expectedMessagesCount = 2
        XCTAssertEqual(try? messageQueryResults.count(), expectedMessagesCount)
        XCTAssertTrue(messageQueryResults[0].imapFlags.flagged) //last message is flagged
        XCTAssertTrue(messageQueryResults[1].imapFlags.flagged) //message 7 ( 10 in order of creation ) is flagged
    }

    func testSearch() {
        // Given
        let messages = createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)
        messages[0].shortMessage = "test search 1"
        messages[1].shortMessage = "test search 2"
        let search = MessageQueryResultsSearch(searchTerm: "search")
        let messageQueryResults = MessageQueryResults(withFolder: cdFolder1.folder(), search: search)

        // When
        XCTAssertNoThrow(try messageQueryResults.startMonitoring())

        // Then
        let expectedMessagesCount = 2

        do {
            let messagesCount = try messageQueryResults.count()
            XCTAssertEqual(messagesCount, expectedMessagesCount)
            XCTAssertTrue(messageQueryResults[0].sent! > messageQueryResults[1].sent!)
            for i in 0..<messagesCount {
                XCTAssertTrue(messageQueryResults[i].shortMessage!.contains(find: "search"))
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDelegateDidInsert() {
        // Given
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }
        createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)
        let exp = expectation(description: "delegate called for didInsert")
        let delegateTest = MessageQueryResultsTestDelegate(withExp: exp, expType: .didChange)
        messageQueryResults.rowDelegate = delegateTest

        // When
        try? messageQueryResults.startMonitoring()
        createCdMessages(cdFolder: cdFolder1, context: moc)
        waitForExpectations(timeout: TestUtil.waitTime)

        // Then
        XCTAssertFalse(delegateTest.didDelete)
        XCTAssertFalse(delegateTest.didUpdate)
        XCTAssertFalse(delegateTest.didMove)
        XCTAssertTrue(delegateTest.didInsert)
        XCTAssertTrue(delegateTest.willChange)
        XCTAssertTrue(delegateTest.didChange)
        XCTAssertEqual(delegateTest.indexPath, IndexPath(item: 0, section: 0))
    }

    func testDelegateDidDelete() {
        // Given
        let messages = createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }
        let exp = expectation(description: "delegate called for didDelete")
        let delegateTest = MessageQueryResultsTestDelegate(withExp: exp, expType: .didChange)
        messageQueryResults.rowDelegate = delegateTest

        // When
        try? messageQueryResults.startMonitoring()
        moc.delete(messages[19])
        moc.delete(messages[18])
        moc.delete(messages[15])
        moc.delete(messages[16])
        moc.delete(messages[0])
        moc.delete(messages[1])
        moc.saveAndLogErrors()
        waitForExpectations(timeout: TestUtil.waitTime)

        // Then
        let expectedMessagesCount = 14
        XCTAssertFalse(delegateTest.didUpdate)
        XCTAssertFalse(delegateTest.didMove)
        XCTAssertFalse(delegateTest.didInsert)
        XCTAssertTrue(delegateTest.didDelete)
        XCTAssertTrue(delegateTest.willChange)
        XCTAssertTrue(delegateTest.didChange)
        XCTAssertEqual(try? messageQueryResults.count(), expectedMessagesCount)
    }

    func testDelegateDidUpdate() {
        // Given
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }
        let messages = createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)
        let exp = expectation(description: "delegate called for didUpdate")
        let delegateTest = MessageQueryResultsTestDelegate(withExp: exp, expType: .didChange)
        messageQueryResults.rowDelegate = delegateTest
        moc.saveAndLogErrors()

        // When
        try? messageQueryResults.startMonitoring()
        messages[0].comments = "new comments"
        waitForExpectations(timeout: TestUtil.waitTime)

        // Then
        let expectedMessagesCount = 20
        XCTAssertFalse(delegateTest.didMove)
        XCTAssertFalse(delegateTest.didInsert)
        XCTAssertFalse(delegateTest.didDelete)
        XCTAssertTrue(delegateTest.didUpdate)
        XCTAssertTrue(delegateTest.willChange)
        XCTAssertTrue(delegateTest.didChange)
        XCTAssertEqual(try? messageQueryResults.count(), expectedMessagesCount)
        XCTAssertEqual(delegateTest.indexPath, IndexPath(item: 19, section: 0))
    }

    func testDelegateDidMove() {
        // Given
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }
        let messages = createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)
        let exp = expectation(description: "delegate called for didMove")
        let delegateTest = MessageQueryResultsTestDelegate(withExp: exp, expType: .didChange)
        messageQueryResults.rowDelegate = delegateTest
        moc.saveAndLogErrors()

        // When
        try? messageQueryResults.startMonitoring()
        let newDate = Date()
        messages[19].sent = newDate
        waitForExpectations(timeout: TestUtil.waitTime)

        // Then
        let expectedMessagesCount = 20
        XCTAssertFalse(delegateTest.didInsert)
        XCTAssertFalse(delegateTest.didDelete)
        XCTAssertFalse(delegateTest.didUpdate)
        XCTAssertTrue(delegateTest.didMove)
        XCTAssertTrue(delegateTest.willChange)
        XCTAssertTrue(delegateTest.didChange)
        XCTAssertEqual(try? messageQueryResults.count(), expectedMessagesCount)
        XCTAssertEqual(delegateTest.indexPath, IndexPath(item: 0, section: 0))
        XCTAssertEqual(delegateTest.newIndexPath, IndexPath(item: 19, section: 0))
    }

    func testDelegateDidMoveToOtherFolderSoDelete() {
        // Given
        guard let messageQueryResults = messageQueryResults else {
            XCTFail()
            return
        }
        let messages = createCdMessages(numMessages: 20, cdFolder: cdFolder1, context: moc)

        let newFolder = Folder(name: "Spam", parent: nil, account: cdFolder1.account!.account(), folderType: FolderType.spam)
        newFolder.session.commit()

        let exp = expectation(description: "delegate called for didDelete")
        let delegateTest = MessageQueryResultsTestDelegate(withExp: exp,
                                                           expType: .didChange)
        messageQueryResults.rowDelegate = delegateTest
        moc.saveAndLogErrors()
        let expectedMessagesCount = 19

        // When
        try? messageQueryResults.startMonitoring()
        let folder2 = (account1.folders!.array[1] as! CdFolder).folder()
        let messageToMove = MessageModelObjectUtils.getMessage(fromCdMessage: messages[19])
        Message.move(messages: [messageToMove], to: folder2)
        waitForExpectations(timeout: TestUtil.waitTime)

        // Then
        XCTAssertFalse(delegateTest.didInsert)
        XCTAssertFalse(delegateTest.didUpdate)
        XCTAssertFalse(delegateTest.didMove)
        XCTAssertTrue(delegateTest.willChange)
        XCTAssertTrue(delegateTest.didDelete)
        XCTAssertTrue(delegateTest.didChange)
        XCTAssertEqual(try? messageQueryResults.count(),
                       expectedMessagesCount)
        XCTAssertEqual(delegateTest.indexPath, IndexPath(item: 0,
                                                         section: 0))
    }
     */
}

// MARK: - Helper

extension MessageQueryResultsTest {

    @discardableResult
    private func createCdMessages(numMessages: Int = 1,
                                  cdFolder: CdFolder,
                                  context: NSManagedObjectContext = Stack.shared.mainContext) -> [CdMessage] {
        let createes = TestUtil.createCdMessages(numMessages: numMessages, cdFolder: cdFolder, moc: moc)
        var uid = 0
        createes.forEach {
            uid += 1
            $0.uid = Int32(uid)
            $0.pEpRating = Int16(PEPRating.unencrypted.rawValue)
        }
        return createes
    }
}

/// MARK: - Delegate test class

class MessageQueryResultsTestDelegate {
    let exp: XCTestExpectation
    let expType: expectationType

    var didMove = false
    var didInsert = false
    var didUpdate = false
    var didDelete = false
    var willChange = false
    var didChange = false
    var indexPath: IndexPath?
    var newIndexPath: IndexPath?

    enum expectationType {
        case didInsert, didUpdate, didDelete, didMove, willChange, didChange
    }

    init(withExp exp: XCTestExpectation, expType: expectationType) {
        self.exp = exp
        self.expType = expType
    }
}

// MARK: - QueryResultsDelegate

extension MessageQueryResultsTestDelegate: QueryResultsIndexPathRowDelegate {

    func didInsertRow(indexPath: IndexPath) {
        didInsert = true
        self.indexPath = indexPath
        if expType == .didInsert { exp.fulfill() }
    }

    func didUpdateRow(indexPath: IndexPath) {
        didUpdate = true
        self.indexPath = indexPath
        if expType == .didUpdate { exp.fulfill() }
    }

    func didDeleteRow(indexPath: IndexPath) {
        didDelete = true
        self.indexPath = indexPath
        if expType == .didDelete { exp.fulfill() }
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        didMove = true
        indexPath = from
        newIndexPath = to
        if expType == .didMove { exp.fulfill() }
    }

    func willChangeResults() {
        willChange = true
        if expType == .willChange { exp.fulfill() }
    }

    func didChangeResults() {
        didChange = true
        if expType == .didChange { exp.fulfill() }
    }
}
