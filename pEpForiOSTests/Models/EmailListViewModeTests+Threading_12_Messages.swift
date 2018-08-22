//
//  EmailListViewModeTests+Threading_12_Messages.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 22.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class EmailListViewModelTests_Threading_12_Messages: CoreDataDrivenTestBase {
    let myWaitTime = TestUtil.waitTimeForever

    var account: Account!
    var inbox: Folder!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        account = cdAccount.account()

        inbox = Folder(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.save()

        let trash = Folder(name: "Trash", parent: nil, account: account, folderType: .trash)
        trash.save()
    }

    // MARK: - Tests

    func testIncoming() {
        let index0 = IndexPath(row: 0, section: 0)

        FolderThreading.override(factory: ThreadAwareFolderFactory())

        let emailListViewModelDelegate = MyEmailListViewModelDelegate()
        let myDisplayedMessage = MyDisplayedMessage()
        let myScreenComposer = MyScreenComposerProtocol()

        let viewModel = EmailListViewModel(
            emailListViewModelDelegate: emailListViewModelDelegate,
            messageSyncService: MyMessageSyncServiceProtocol(),
            folderToShow: inbox)

        viewModel.currentDisplayedMessage = myDisplayedMessage
        viewModel.screenComposer = myScreenComposer

        let msg1 = createMessage(number: 1, referencing: [])
        emailListViewModelDelegate.didInsertData = DidInsertData(
            expectation: expectation(description: "testIncoming didInsertData 1st message"),
            indexPaths: [index0])
        viewModel.didCreate(messageFolder: msg1)

        waitForExpectations(timeout: myWaitTime) { err in
            XCTAssertNil(err)
        }

        myDisplayedMessage.messageModel = msg1
        myDisplayedMessage.detailTypeVar = .single
        myScreenComposer.didRequestShowThreadView = DidRequestShowThreadView(
            expectation: expectation(
                description: "testIncoming didRequestShowThreadView on 2nd message"),
            message: msg1)

        emailListViewModelDelegate.reset()
        emailListViewModelDelegate.didUpdateData = DidUpdateData(
            expectation: expectation(description: "testIncoming didUpdateData on 2nd message"),
            indexPaths: [index0])
        let msg2 = createMessage(number: 2, referencing: [1])
        viewModel.didCreate(messageFolder: msg2)

        waitForExpectations(timeout: myWaitTime) { err in
            XCTAssertNil(err)
        }

        myDisplayedMessage.messageModel = msg2
        myDisplayedMessage.detailTypeVar = .thread

        emailListViewModelDelegate.reset()
        emailListViewModelDelegate.didUpdateData = DidUpdateData(
            expectation: expectation(description: "testIncoming didUpdateData on 3rd message"),
            indexPaths: [index0])
        let msg3 = createMessage(number: 3, referencing: [1, 2])
        viewModel.didCreate(messageFolder: msg3)

        waitForExpectations(timeout: myWaitTime) { err in
            XCTAssertNil(err)
        }

        myDisplayedMessage.messageModel = msg3
    }

    // MARK: - Helpers

    func createMessage(number: Int, referencing: [Int]) -> Message {
        let aMessage = TestUtil.createMessage(uid: number, inFolder: inbox)
        aMessage.longMessage = "\(number)"
        aMessage.references = referencing.map { return "\($0)" }
        aMessage.save()
        return aMessage
    }

    // MARK: - Delegates

    class MyMessageSyncServiceProtocol: MessageSyncServiceProtocol {
        func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
        }

        func requestFetchOlderMessages(inFolder folder: Folder) {
        }
    }

    class MyDisplayedMessage: DisplayedMessage {
        var messageModel: Message?
        var detailTypeVar: EmailDetailType = .single

        func update(forMessage message: Message) {
        }

        func detailType() -> EmailDetailType {
            return detailTypeVar
        }
    }

    struct DidRequestShowThreadView {
        let expectation: XCTestExpectation
        let message: Message
    }

    class MyScreenComposerProtocol: ScreenComposerProtocol {
        var didRequestShowThreadView: DidRequestShowThreadView?

        func emailListViewModel(_ emailListViewModel: EmailListViewModel,
                                requestsShowThreadViewFor message: Message) {
            if let theDidRequestShowThreadView = didRequestShowThreadView {
                XCTAssertEqual(didRequestShowThreadView?.message, message)
                theDidRequestShowThreadView.expectation.fulfill()
            }
        }

        func emailListViewModel(_ emailListViewModel: EmailListViewModel,
                                requestsShowEmailViewFor message: Message) {
        }
    }

    struct DidInsertData {
        let expectation: XCTestExpectation
        let indexPaths: [IndexPath]
    }

    struct DidUpdateData {
        let expectation: XCTestExpectation
        let indexPaths: [IndexPath]
    }

    class MyEmailListViewModelDelegate: EmailListViewModelDelegate {
        var didInsertData: DidInsertData?
        var didUpdateData: DidUpdateData?

        func reset() {
            didInsertData = nil
            didUpdateData = nil
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didInsertDataAt indexPaths: [IndexPath]) {
            if let theDidInsertData = didInsertData {
                XCTAssertEqual(theDidInsertData.indexPaths, indexPaths)
                print("fulfill \(theDidInsertData.expectation)")
                theDidInsertData.expectation.fulfill()
            }
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didUpdateDataAt indexPaths: [IndexPath]) {
            if let theDidUpdateData = didUpdateData {
                XCTAssertEqual(theDidUpdateData.indexPaths, indexPaths)
                print("fulfill \(theDidUpdateData.expectation)")
                theDidUpdateData.expectation.fulfill()
            }
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didRemoveDataAt indexPaths: [IndexPath]) {
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didMoveData atIndexPath: IndexPath,
                                toIndexPath: IndexPath) {
        }

        func emailListViewModel(viewModel: EmailListViewModel,
                                didUpdateUndisplayedMessage message: Message) {
        }

        func toolbarIs(enabled: Bool) {
        }

        func showUnflagButton(enabled: Bool) {
        }

        func showUnreadButton(enabled: Bool) {
        }

        func updateView() {
        }
    }
}
