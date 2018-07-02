//
//  EmailListViewModel+ThreadingTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 25.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class EmailListViewModel_ThreadingTests: CoreDataDrivenTestBase {
    var account: Account!
    var inbox: Folder!
    var topMessages = [Message]()
    let emailListViewModelDelegate = MyEmailListViewModelDelegate()
    let messageSyncServiceProtocol = MyMessageSyncServiceProtocol()
    var emailListViewModel: EmailListViewModel!
    var displayedMessage = MyDisplayedMessage()
    var updateThreadListDelegate = MyUpdateThreadListDelegate()

    // MARK: - Tests

    func testUnthreadedIncomingTopMessage() {
        FolderThreading.override(factory: ThreadUnAwareFolderFactory())
        setUpTopMessages()
        let _ = testIncomingMessage(references: [], indexPathUpdated: nil)
    }

    func testThreadedIncomingChildMessageToSingleUndisplayedParent() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        // topMessages[0] is the oldest, so it's last in the list
        let _ = testIncomingMessage(references: [topMessages[1]],
                                    indexPathUpdated: IndexPath(row: 3, section: 0))
        let _ = testIncomingMessage(references: [topMessages[0]],
                                    indexPathUpdated: IndexPath(row: 4, section: 0))
    }

    func testThreadedIncomingChildMessageToUndisplayedParents() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        // Will update the first (newest) message it finds,
        // which is topMessages[1] with row 3.
        let _ = testIncomingMessage(references: [topMessages[0], topMessages[1]],
                                    indexPathUpdated: IndexPath(row: 3, section: 0))
    }

    func testThreadedIncomingChildMessageToSingleDisplayedParent() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        let theDisplayedMessage = topMessages[1]
        displayedMessage.messageModel = theDisplayedMessage

        // topMessages[0] is the oldest, so it's last in the list
        let _ = testIncomingMessage(references: [theDisplayedMessage],
                                    indexPathUpdated: nil)
    }

    func testThreadedUpdateTopMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        let theDisplayedMessage = topMessages[1]
        displayedMessage.messageModel = theDisplayedMessage

        let _ = testIncomingMessage(references: [theDisplayedMessage],
                                    indexPathUpdated: nil)

        topMessages[0].imapFlags?.flagged = true
        XCTAssertTrue(topMessages[0].imapFlags?.flagged ?? false)

        emailListViewModelDelegate.expectationUpdated = ExpectationTopMessageUpdated(
            indexPath: IndexPath(row: 4, section: 0),
            expectation: expectation(description: "expectationUpdated"))

        emailListViewModel.didUpdate(messageFolder: topMessages[0])

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }
    }

    func testThreadedUpdateDisplayedChildMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        let theDisplayedMessage = topMessages[1]
        displayedMessage.messageModel = theDisplayedMessage

        let incomingMessage = testIncomingMessage(references: [theDisplayedMessage],
                                                  indexPathUpdated: nil)

        incomingMessage.imapFlags?.flagged = true
        XCTAssertTrue(incomingMessage.imapFlags?.flagged ?? false)

        updateThreadListDelegate.expectationUpdated = ExpectationChildMessageUpdated(
            message: incomingMessage,
            expectation: expectation(description: "expectationUpdated"))

        emailListViewModel.didUpdate(messageFolder: incomingMessage)

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }
    }

    func testThreadedUpdateUnDisplayedChildMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        let unDisplayedMessage = topMessages[1]
        displayedMessage.messageModel = topMessages[0]

        let incomingMessage = testIncomingMessage(references: [unDisplayedMessage],
                                                  indexPathUpdated: IndexPath(row: 3, section: 0))
        incomingMessage.imapFlags?.flagged = true
        XCTAssertTrue(incomingMessage.imapFlags?.flagged ?? false)

        emailListViewModelDelegate.expectationUndiplayedMessageUpdated =
            ExpectationUndiplayedMessageUpdated(
                message: incomingMessage,
                expectation: expectation(description: "expectationUndiplayedMessageUpdated"))

        emailListViewModel.didUpdate(messageFolder: incomingMessage)

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }
    }

    func testThreadedDeleteDisplayedChildMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        let theDisplayedMessage = topMessages[1]
        displayedMessage.messageModel = theDisplayedMessage

        let incomingMessage = testIncomingMessage(references: [theDisplayedMessage],
                                                  indexPathUpdated: nil)

        updateThreadListDelegate.expectationChildMessageDeleted = ExpectationChildMessageDeleted(
            message: incomingMessage,
            expectation: expectation(description: "expectationChildMessageDeleted"))

        incomingMessage.imapDelete()
        emailListViewModel.didDelete(messageFolder: incomingMessage)

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }
    }

    func testThreadedDeleteUnDisplayedChildMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        let theDisplayedMessage = topMessages[1]
        displayedMessage.messageModel = theDisplayedMessage

        let incomingMessage = testIncomingMessage(references: [topMessages[0]],
                                                  indexPathUpdated: IndexPath(row: 4, section: 0))

        emailListViewModelDelegate.expectationUpdated = ExpectationTopMessageUpdated(
            indexPath: IndexPath(row: 4, section: 0),
            expectation: expectation(description: "expectationUpdated"))

        incomingMessage.imapDelete()
        emailListViewModel.didDelete(messageFolder: incomingMessage)

        waitForExpectations(timeout: TestUtil.waitTimeForever) { err in
            XCTAssertNil(err)
        }
    }

    func testUnThreadedUserDeleteUndisplayedMessage() {
        FolderThreading.override(factory: ThreadUnAwareFolderFactory())
        setUpTopMessages()

        let indexPath = IndexPath(row: 0, section: 0)
        emailListViewModelDelegate.expectationTopMessageDeleted =
            ExpectationViewModelDelegateTopMessageDeleted(
                indexPath: indexPath,
                expectation: expectation(description: "expectationTopMessageDeleted"))

        emailListViewModel.delete(forIndexPath: indexPath)

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }
    }

    func testUnThreadedUserDeleteDisplayedMessage() {
        FolderThreading.override(factory: ThreadUnAwareFolderFactory())
        setUpTopMessages()

        emailListViewModel.currentDisplayedMessage = displayedMessage

        let messageToBeDeleted = topMessages.last!
        displayedMessage.messageModel = messageToBeDeleted

        let indexPath = IndexPath(row: 0, section: 0)
        emailListViewModelDelegate.expectationTopMessageDeleted =
            ExpectationViewModelDelegateTopMessageDeleted(
                indexPath: indexPath,
                expectation: expectation(description: "expectationTopMessageDeleted"))

        emailListViewModel.delete(forIndexPath: indexPath)

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }
    }

    func testThreadedUserDeleteMessageWithoutChild() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        let indexPath = IndexPath(row: 0, section: 0)
        emailListViewModelDelegate.expectationTopMessageDeleted =
            ExpectationViewModelDelegateTopMessageDeleted(
                indexPath: indexPath,
                expectation: expectation(description: "expectationTopMessageDeleted"))

        emailListViewModel.delete(forIndexPath: indexPath)

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }
    }

    // MARK: - Internal - Helpers

    func setUpTopMessages() {
        account = cdAccount.account()

        inbox = Folder.init(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.save()

        let trash = Folder.init(name: "Trash", parent: nil, account: account, folderType: .trash)
        trash.save()

        topMessages.removeAll()

        for i in 1...5 {
            let msg = createMessage(number: i)
            topMessages.append(msg)
            msg.save()
        }

        emailListViewModelDelegate.expectationViewUpdated = expectation(
            description: "expectationViewUpdated")

        emailListViewModel = EmailListViewModel(
            emailListViewModelDelegate: emailListViewModelDelegate,
            messageSyncService: messageSyncServiceProtocol,
            folderToShow: inbox)

        emailListViewModel.updateThreadListDelegate = updateThreadListDelegate

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }

        XCTAssertNil(emailListViewModel.currentDisplayedMessage)
        XCTAssertNil(emailListViewModel.currentDisplayedMessage?.messageModel)
    }

    func testIncomingMessage(references: [Message],
                             indexPathUpdated: IndexPath?) -> Message {
        XCTAssertEqual(emailListViewModel.messages.count, topMessages.count)
        emailListViewModel.currentDisplayedMessage = displayedMessage

        let incomingMessage = createMessage(number: topMessages.count + 1)
        incomingMessage.references = references.map {
            return $0.messageID
        }

        if references.isEmpty {
            // expect top message
            emailListViewModelDelegate.expectationInserted = ExpectationTopMessageInserted(
                indexPath: IndexPath(row: 0, section: 0),
                expectation: expectation(description: "expectationInserted"))
        } else if let indexPath = indexPathUpdated {
            emailListViewModelDelegate.expectationUpdated = ExpectationTopMessageUpdated(
                indexPath: indexPath,
                expectation: expectation(description: "expectationUpdated"))
        } else {
            // expect child message
            updateThreadListDelegate.expectationAdded = ExpectationChildMessageAdded(
                expectation: expectation(description: "expectationAdded"))
        }
        emailListViewModel.didCreate(messageFolder: incomingMessage)

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }

        return incomingMessage
    }

    func topMessage(byUID uid: Int) -> Message {
        return topMessages[uid-1]
    }

    func createMessage(number: Int, inFolder folder: Folder? = nil) -> Message {
        let msg = Message.init(uuid: "\(number)",
            uid: UInt(number),
            parentFolder: folder ?? inbox)
        XCTAssertEqual(msg.uid, UInt(number))
        msg.pEpRatingInt = Int(PEP_rating_unreliable.rawValue)
        msg.received = Date.init(timeIntervalSince1970: Double(number))
        msg.sent = msg.received
        return msg
    }

    // MARK: - Internal - Delegate parameters

    /**
     EmailListViewModelDelegate insertion of a top message.
     */
    struct ExpectationTopMessageInserted {
        let indexPath: IndexPath
        let expectation: XCTestExpectation
    }

    /**
     EmailListViewModelDelegate update of a top message.
     */
    struct ExpectationTopMessageUpdated {
        let indexPath: IndexPath
        let expectation: XCTestExpectation
    }

    /**
     EmailListViewModelDelegate update of an undisplayed (child) message.
     */
    struct ExpectationUndiplayedMessageUpdated {
        let message: Message
        let expectation: XCTestExpectation
    }

    /**
     UpdateThreadListDelegate insertion of a child message.
     */
    struct ExpectationChildMessageAdded {
        let expectation: XCTestExpectation
    }

    /**
     UpdateThreadListDelegate update of a child message.
     */
    struct ExpectationChildMessageUpdated {
        let message: Message
        let expectation: XCTestExpectation
    }

    /**
     UpdateThreadListDelegate deletion of a child message.
     */
    struct ExpectationChildMessageDeleted {
        let message: Message
        let expectation: XCTestExpectation
    }

    /**
     UpdateThreadListDelegate deletion of a top message.
     */
    struct ExpectationUpdateThreadListDelegateTopMessageDeleted {
        let message: Message
        let expectation: XCTestExpectation
    }

    /**
     EmailListViewModelDelegate user-deletion of a top message
     (both unthreaded and threaded).
     */
    struct ExpectationViewModelDelegateTopMessageDeleted {
        let indexPath: IndexPath
        let expectation: XCTestExpectation
    }

    // MARK: - Internal - Delegates

    class MyDisplayedMessage: DisplayedMessage {
        var messageModel: Message?

        func update(forMessage message: Message) {
        }
    }

    class MyMessageSyncServiceProtocol: MessageSyncServiceProtocol {
        weak var errorDelegate: MessageSyncServiceErrorDelegate?
        weak var sentDelegate: MessageSyncServiceSentDelegate?
        weak var syncDelegate: MessageSyncServiceSyncDelegate?
        weak var stateDelegate: MessageSyncServiceStateDelegate?
        weak var flagsUploadDelegate: MessageSyncFlagsUploadDelegate?

        func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
        }

        func requestFetchOlderMessages(inFolder folder: Folder) {
        }

        func requestDraft(message: Message) {
        }

        func requestSend(message: Message) {
        }

        func requestFlagChange(message: Message) {
        }

        func requestMessageSync(folder: Folder) {
        }

        func start(account: Account) {
        }

        func cancel(account: Account) {
        }
    }

    class MyEmailListViewModelDelegate: EmailListViewModelDelegate {
        var expectationViewUpdated: XCTestExpectation?
        var expectationUpdated: ExpectationTopMessageUpdated?
        var expectationInserted: ExpectationTopMessageInserted?
        var expectationUndiplayedMessageUpdated: ExpectationUndiplayedMessageUpdated?
        var expectationTopMessageDeleted: ExpectationViewModelDelegateTopMessageDeleted?

        func emailListViewModel(viewModel: EmailListViewModel,
                                didInsertDataAt indexPath: IndexPath) {
            if let exp = expectationInserted {
                XCTAssertEqual(indexPath, exp.indexPath)
                exp.expectation.fulfill()
            }
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didUpdateDataAt indexPath: IndexPath) {
            if let exp = expectationUpdated {
                XCTAssertEqual(indexPath, exp.indexPath)
                exp.expectation.fulfill()
            }
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didRemoveDataAt indexPath: IndexPath) {
            if let exp = expectationTopMessageDeleted {
                XCTAssertEqual(indexPath, exp.indexPath)
                exp.expectation.fulfill()
            }
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didUpdateUndisplayedMessage message: Message) {
            if let exp = expectationUndiplayedMessageUpdated {
                XCTAssertEqual(message, exp.message)
                exp.expectation.fulfill()
            }
        }

        func toolbarIs(enabled: Bool) {
        }

        func showUnflagButton(enabled: Bool) {
        }

        func showUnreadButton(enabled: Bool) {
        }

        func updateView() {
            expectationViewUpdated?.fulfill()
        }
    }

    class MyUpdateThreadListDelegate: UpdateThreadListDelegate {
        var expectationAdded: ExpectationChildMessageAdded?
        var expectationUpdated: ExpectationChildMessageUpdated?
        var expectationChildMessageDeleted: ExpectationChildMessageDeleted?

        func deleted(message: Message) {
            if let exp = expectationChildMessageDeleted {
                XCTAssertEqual(message, exp.message)
                exp.expectation.fulfill()
            }
        }

        func updated(message: Message) {
            if let exp = expectationUpdated {
                XCTAssertEqual(exp.message, message)
                exp.expectation.fulfill()
            }
        }

        func added(message: Message) {
            if let exp = expectationAdded {
                exp.expectation.fulfill()
            }
        }
    }
}
