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

    override func setUp() {
        super.setUp()

        account = cdAccount.account()
        inbox = Folder.init(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.save()
        topMessages.removeAll()

        for i in 1...5 {
            let msg = createMessage(number: i)
            topMessages.append(msg)
            msg.save()
        }

        emailListViewModel = EmailListViewModel(
            emailListViewModelDelegate: emailListViewModelDelegate,
            messageSyncService: messageSyncServiceProtocol,
            folderToShow: inbox)
    }

    // MARK - Tests

    func testIncomingUnthreaded() {
        emailListViewModelDelegate.expectationViewUpdated = expectation(description: "wait")

        waitForExpectations(timeout: TestUtil.waitTime) { err in
            XCTAssertNil(err)
        }

        XCTAssertEqual(emailListViewModel.messages.count, topMessages.count)
        XCTAssertNil(emailListViewModel.currentDisplayedMessage)

        XCTAssertNil(emailListViewModel.currentDisplayedMessage?.messageModel)
        emailListViewModel.currentDisplayedMessage = displayedMessage

        displayedMessage.messageModel = topMessage(byUID: 3)

        let incoming = createMessage(number: topMessages.count + 1)
        emailListViewModelDelegate.expectationInserted = ExpectationInserted(
            expectationInserted: expectation(
                description: "expectationInserted"),
            indexPath: IndexPath(row: 0, section: 0))
        emailListViewModel.didCreate(messageFolder: incoming)

        waitForExpectations(timeout: TestUtil.waitTime) { err in
            XCTAssertNil(err)
        }
    }

    // MARK - Internal - Helpers

    func topMessage(byUID uid: Int) -> Message {
        return topMessages[uid-1]
    }

    func createMessage(number: Int) -> Message {
        let msg = Message.init(uuid: "\(number)", parentFolder: inbox)
        msg.imapFlags?.uid = Int32(number)
        msg.pEpRatingInt = Int(PEP_rating_unreliable.rawValue)
        return msg
    }

    // MARK - Internal - Delegates

    class ExpectationInserted {
        let expectationInserted: XCTestExpectation
        let indexPath: IndexPath

        init(expectationInserted: XCTestExpectation, indexPath: IndexPath) {
            self.expectationInserted = expectationInserted
            self.indexPath = indexPath
        }
    }

    class MyDisplayedMessage: DisplayedMessage {
        var messageModel: Message?

        func update(forMessage message: Message) {
            print("\(#function) message: \(message)")
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
}
