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

    // MARK - Tests

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

    func testUpdateTopMessage() {
        FolderThreading.override(factory: ThreadAwareFolderFactory())
        setUpTopMessages()

        let theDisplayedMessage = topMessages[1]
        displayedMessage.messageModel = theDisplayedMessage

        let _ = testIncomingMessage(references: [theDisplayedMessage],
                                    indexPathUpdated: nil)

        topMessages[0].imapFlags?.flagged = true
        XCTAssertTrue(topMessages[0].imapFlags?.flagged ?? false)

        emailListViewModelDelegate.expectationUpdated = ExpectationUpdated(
            expectationUpdated: expectation(description: "expectationUpdated"),
            indexPath: IndexPath(row: 4, section: 0))

        emailListViewModel.didUpdate(messageFolder: topMessages[0])

        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
            XCTAssertNil(err)
        }
    }

    // MARK - Internal - Helpers

    func setUpTopMessages() {
        account = cdAccount.account()
        inbox = Folder.init(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.save()
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
            emailListViewModelDelegate.expectationInserted = ExpectationInserted(
                expectationInserted: expectation(
                    description: "expectationInserted"),
                indexPath: IndexPath(row: 0, section: 0))
        } else if let indexPath = indexPathUpdated {
            emailListViewModelDelegate.expectationUpdated = ExpectationUpdated(
                expectationUpdated: expectation(description: "expectationUpdated"),
                indexPath: indexPath)
        } else {
            // expect child message
            updateThreadListDelegate.expectationAdded = ExpectationAdded(
                expectationAdded: expectation(description: "expectationAdded"))
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

    func createMessage(number: Int) -> Message {
        let msg = Message.init(uuid: "\(number)", parentFolder: inbox)
        msg.imapFlags?.uid = Int32(number)
        msg.pEpRatingInt = Int(PEP_rating_unreliable.rawValue)
        msg.received = Date.init(timeIntervalSince1970: Double(number))
        msg.sent = msg.received
        return msg
    }

    // MARK - Internal - Delegates

    /**
     EmailListViewModelDelegate insertion of a top message.
     */
    class ExpectationInserted {
        let expectationInserted: XCTestExpectation
        let indexPath: IndexPath

        init(expectationInserted: XCTestExpectation, indexPath: IndexPath) {
            self.expectationInserted = expectationInserted
            self.indexPath = indexPath
        }
    }

    /**
     EmailListViewModelDelegate insertion of a top message.
     */
    class ExpectationUpdated {
        let expectationUpdated: XCTestExpectation
        let indexPath: IndexPath

        init(expectationUpdated: XCTestExpectation, indexPath: IndexPath) {
            self.expectationUpdated = expectationUpdated
            self.indexPath = indexPath
        }
    }

    /**
     UpdateThreadListDelegate insertion of a child message.
     */
    class ExpectationAdded {
        let expectationAdded: XCTestExpectation

        init(expectationAdded: XCTestExpectation) {
            self.expectationAdded = expectationAdded
        }
    }

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
        var expectationUpdated: ExpectationUpdated?
        var expectationInserted: ExpectationInserted?

        func emailListViewModel(viewModel: EmailListViewModel,
                                didInsertDataAt indexPath: IndexPath) {
            if let exp = expectationInserted {
                XCTAssertEqual(indexPath, exp.indexPath)
                exp.expectationInserted.fulfill()
            }
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didUpdateDataAt indexPath: IndexPath) {
            if let exp = expectationUpdated {
                XCTAssertEqual(indexPath, exp.indexPath)
                exp.expectationUpdated.fulfill()
            }
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didRemoveDataAt indexPath: IndexPath) {
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
        var expectationAdded: ExpectationAdded?

        func deleted(message: Message) {
        }

        func updated(message: Message) {
        }

        func added(message: Message) {
            if let exp = expectationAdded {
                exp.expectationAdded.fulfill()
            }
        }
    }
}
