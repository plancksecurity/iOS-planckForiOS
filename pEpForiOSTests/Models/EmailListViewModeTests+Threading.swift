//
//  EmailListViewModelTests_Threading.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 25.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class EmailListViewModelTests_Threading: CoreDataDrivenTestBase {
//    var account: Account!
//    var inbox: Folder!
//    var topMessages = [Message]()
//    let emailListViewModelDelegate = MyEmailListViewModelDelegate()
//    let screenComposerProtocol = MyScreenComposerProtocol()
//    let messageSyncServiceProtocol = MyMessageSyncServiceProtocol()
//    var emailListViewModel: EmailListViewModel!
//    var displayedMessage = MyDisplayedMessage()
//    var updateThreadListDelegate = MyUpdateThreadListDelegate()
//
//    static let numberOfTopMessages = 5
//
//    /**
//     The index of `topMessages[0]`, that is, the oldest one.
//     */
//    let indexOfTopMessage0 = IndexPath(row: numberOfTopMessages - 1, section: 0)
//
//    /**
//     The index of `topMessages[1]`, that is, the second oldest one.
//     */
//    let indexOfTopMessage1 = IndexPath(row: numberOfTopMessages - 2, section: 0)
//
//    /**
//     The index of `topMessages.last`, that is, the newest one.
//     */
//    let indexOfTopMessageNewest = IndexPath(row: 0, section: 0)
//
//    // MARK: - Setup
//
//    override func setUp() {
//        super.setUp()
//
//        account = cdAccount.account()
//
//        inbox = Folder.init(name: "INBOX", parent: nil, account: account, folderType: .inbox)
//        inbox.save()
//
//        let trash = Folder.init(name: "Trash", parent: nil, account: account, folderType: .trash)
//        trash.save()
//    }
//
//    // MARK: - Tests
//
//    func testUnthreadedIncomingTopMessage() {
//        FolderThreading.override(factory: ThreadUnAwareFolderFactory())
//        setUpTopMessages()
//        let _ = testIncomingMessage(parameters: IncomingMessageParameters.noMessage([], nil),
//                                    indexPathUpdated: nil)
//    }
//
//    func testThreadedIncomingChildMessageToSingleUndisplayedParent() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        // topMessages[0] is the oldest, so it's last in the list
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([topMessages[1]], nil),
//            indexPathUpdated: indexOfTopMessage1)
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([topMessages[0]], nil),
//            indexPathUpdated: indexOfTopMessage0)
//    }
//
//    func testThreadedIncomingSentChildMessageToSingleUndisplayedParent() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        let sentFolder = Folder.init(name: "Sent",
//                                     parent: nil,
//                                     account: account,
//                                     folderType: .sent)
//        sentFolder.save()
//
//        // topMessages[0] is the oldest, so it's last in the list
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([topMessages[1]], sentFolder),
//            indexPathUpdated: indexOfTopMessage1)
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([topMessages[0]], nil),
//            indexPathUpdated: indexOfTopMessage0)
//    }
//
//    func testThreadedIncomingChildMessageToUndisplayedParents() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        // Will update the first (newest) message it finds,
//        // which is topMessages[1] with row 3.
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([topMessages[0], topMessages[1]], nil),
//            indexPathUpdated: indexOfTopMessage1)
//    }
//
//    func testThreadedIncomingChildMessageToSingleDisplayedParent() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        let theDisplayedMessage = topMessages[1]
//        displayedMessage.messageModel = theDisplayedMessage
//
//        // topMessages[0] is the oldest, so it's last in the list
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([theDisplayedMessage], nil),
//            indexPathUpdated: nil,
//            openThread: true)
//    }
//
//    func testThreadedUpdateTopMessage() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        let theDisplayedMessage = topMessages[1]
//        displayedMessage.messageModel = theDisplayedMessage
//
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([theDisplayedMessage], nil),
//            indexPathUpdated: nil,
//            openThread: true)
//
//        topMessages[0].imapFlags?.flagged = true
//        XCTAssertTrue(topMessages[0].imapFlags?.flagged ?? false)
//
//        emailListViewModelDelegate.expectationUpdated = ExpectationTopMessageUpdated(
//            indexPath: indexOfTopMessage0,
//            expectation: expectation(description: "expectationUpdated"))
//
//        emailListViewModel.didUpdate(messageFolder: topMessages[0])
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//    }
//
//    func testThreadedUpdateDisplayedChildMessage() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        let theDisplayedMessage = topMessages[1]
//        displayedMessage.messageModel = theDisplayedMessage
//
//        let incomingMessage = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([theDisplayedMessage], nil),
//            indexPathUpdated: nil,
//            openThread: true)
//
//        incomingMessage.imapFlags?.flagged = true
//        XCTAssertTrue(incomingMessage.imapFlags?.flagged ?? false)
//
//        updateThreadListDelegate.expectationUpdated = ExpectationChildMessageUpdated(
//            message: incomingMessage,
//            expectation: expectation(description: "expectationUpdated"))
//
//        emailListViewModel.didUpdate(messageFolder: incomingMessage)
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//    }
//
//    func testThreadedUpdateUnDisplayedChildMessage() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        let unDisplayedMessage = topMessages[1]
//        displayedMessage.messageModel = topMessages[0]
//
//        let incomingMessage = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([unDisplayedMessage], nil),
//            indexPathUpdated: indexOfTopMessage1)
//        incomingMessage.imapFlags?.flagged = true
//        XCTAssertTrue(incomingMessage.imapFlags?.flagged ?? false)
//
//        emailListViewModelDelegate.expectationUndiplayedMessageUpdated =
//            ExpectationUndiplayedMessageUpdated(
//                message: incomingMessage,
//                expectation: expectation(description: "expectationUndiplayedMessageUpdated"))
//
//        emailListViewModel.didUpdate(messageFolder: incomingMessage)
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//    }
//
//    func testThreadedDeleteDisplayedChildMessage() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        let theDisplayedMessage = topMessages[1]
//        displayedMessage.messageModel = theDisplayedMessage
//
//        let incomingMessage = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([theDisplayedMessage], nil),
//            indexPathUpdated: nil,
//            openThread: true)
//
//        updateThreadListDelegate.expectationChildMessageDeleted = ExpectationChildMessageDeleted(
//            message: incomingMessage,
//            expectation: expectation(description: "expectationChildMessageDeleted"))
//
//        let refs = Set(incomingMessage.references)
//        incomingMessage.imapDelete()
//        emailListViewModel.didDelete(messageFolder: incomingMessage, belongingToThread: refs)
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//    }
//
//    func testThreadedDeleteUnDisplayedChildMessage() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        let theDisplayedMessage = topMessages[1]
//        displayedMessage.messageModel = theDisplayedMessage
//
//        let incomingMessage = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([topMessages[0]], nil),
//            indexPathUpdated: indexOfTopMessage0)
//
//        emailListViewModelDelegate.expectationUpdated = ExpectationTopMessageUpdated(
//            indexPath: indexOfTopMessage0,
//            expectation: expectation(description: "expectationUpdated"))
//
//        let refs = Set(incomingMessage.references)
//        incomingMessage.imapDelete()
//        emailListViewModel.didDelete(messageFolder: incomingMessage, belongingToThread: refs)
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//    }
//
//    func testUnThreadedUserDeleteUndisplayedMessage() {
//        FolderThreading.override(factory: ThreadUnAwareFolderFactory())
//        setUpTopMessages()
//
//        emailListViewModelDelegate.expectationTopMessageDeleted =
//            ExpectationViewModelDelegateTopMessageDeleted(
//                indexPath: indexOfTopMessageNewest,
//                expectation: expectation(description: "expectationTopMessageDeleted"))
//
//        emailListViewModel.delete(forIndexPath: indexOfTopMessageNewest)
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//    }
//
//    func testUnThreadedUserDeleteDisplayedMessage() {
//        FolderThreading.override(factory: ThreadUnAwareFolderFactory())
//        setUpTopMessages()
//
//        emailListViewModel.currentDisplayedMessage = displayedMessage
//
//        let messageToBeDeleted = topMessages.last!
//        displayedMessage.messageModel = messageToBeDeleted
//
//        emailListViewModelDelegate.expectationTopMessageDeleted =
//            ExpectationViewModelDelegateTopMessageDeleted(
//                indexPath: indexOfTopMessageNewest,
//                expectation: expectation(description: "expectationTopMessageDeleted"))
//
//        emailListViewModel.delete(forIndexPath: indexOfTopMessageNewest)
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//    }
//
//    func testThreadedUserDeleteMessageWithoutChild() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        emailListViewModelDelegate.expectationTopMessageDeleted =
//            ExpectationViewModelDelegateTopMessageDeleted(
//                indexPath: indexOfTopMessageNewest,
//                expectation: expectation(description: "expectationTopMessageDeleted"))
//
//        emailListViewModel.delete(forIndexPath: indexOfTopMessageNewest)
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//    }
//
//    enum SentOrTrashed {
//        case sent, trashed
//    }
//
//    func testThreadedReferencesSentMessage() {
//        testThreadedReferencesSentOrTrashedExistingMessage(sentOrTrashed: .sent)
//    }
//
//    func testThreadedReferencesTrashedMessage() {
//        testThreadedReferencesSentOrTrashedExistingMessage(sentOrTrashed: .trashed)
//    }
//
//    func testThreadedSpecial() {
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages(
//            [TestUtil.createSpecialMessage(number: 0, folder: inbox, receiver: account.user)])
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.message(
//                TestUtil.createSpecialMessage(number: 1, folder: inbox, receiver: account.user)),
//            indexPathUpdated: IndexPath(row: 0, section: 0))
//        let _ = testIncomingMessage(
//            parameters: IncomingMessageParameters.message(
//                TestUtil.createSpecialMessage(number: 2, folder: inbox, receiver: account.user)),
//            indexPathUpdated: IndexPath(row: 0, section: 0))
//    }
//
//    // MARK: - Internal - Helpers
//
//    func setUpTopMessages(_ messages: [Message] = []) {
//        if messages.isEmpty {
//            for i in 1...EmailListViewModelTests_Threading.numberOfTopMessages {
//                let msg = TestUtil.createMessage(uid: i, inFolder: inbox)
//                topMessages.append(msg)
//                msg.save()
//            }
//        } else {
//            topMessages = messages
//        }
//
//        emailListViewModelDelegate.expectationViewUpdated = expectation(
//            description: "expectationViewUpdated")
//
//        emailListViewModel = EmailListViewModel(
//            emailListViewModelDelegate: emailListViewModelDelegate,
//            messageSyncService: messageSyncServiceProtocol,
//            folderToShow: inbox)
//        emailListViewModel.screenComposer = self.screenComposerProtocol
//        emailListViewModel.updateThreadListDelegate = updateThreadListDelegate
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//
//        XCTAssertNil(emailListViewModel.currentDisplayedMessage)
//        XCTAssertNil(emailListViewModel.currentDisplayedMessage?.messageModel)
//    }
//
//    enum IncomingMessageParameters {
//        case message (Message)
//        case noMessage ([Message], Folder?)
//    }
//
//    func testIncomingMessage(parameters: IncomingMessageParameters,
//                             indexPathUpdated: IndexPath?,
//                             openThread: Bool = false) -> Message {
//        XCTAssertEqual(emailListViewModel.messages.count, topMessages.count)
//        emailListViewModel.currentDisplayedMessage = displayedMessage
//
//        var theReferences: [MessageID]
//        var optIncomingMessage: Message?
//
//        switch parameters {
//        case .noMessage(let (references, folder)):
//            let theFolder: Folder = folder ?? inbox
//            let incomingMessage = TestUtil.createMessage(uid: TestUtil.nextUid(),
//                                                         inFolder: theFolder)
//            theReferences = references.map {
//                return $0.messageID
//            }
//            incomingMessage.references = theReferences
//            incomingMessage.save()
//
//            optIncomingMessage = incomingMessage
//        case .message(let msg):
//            theReferences = msg.references
//            optIncomingMessage = msg
//        }
//
//        if theReferences.isEmpty {
//            // expect top message
//            emailListViewModelDelegate.expectationInserted = ExpectationTopMessageInserted(
//                indexPath: indexOfTopMessageNewest,
//                expectation: expectation(description: "expectationInserted"))
//        } else if let indexPath = indexPathUpdated {
//            emailListViewModelDelegate.expectationUpdated = ExpectationTopMessageUpdated(
//                indexPath: indexPath,
//                expectation: expectation(description: "expectationUpdated"))
//        } else {
//            if openThread {
//                //expect transforming from single to thread
//                screenComposerProtocol.expectationShowThreadView = ExpectationShowThreadView(
//                    expectation: expectation(description: "expectationShowThreadView"))
//            } else {
//                // expect child message to existing thread
//                updateThreadListDelegate.expectationAdded = ExpectationChildMessageAdded(
//                    expectation: expectation(description: "expectationAdded"))
//            }
//        }
//
//        emailListViewModel.didCreate(messageFolder: optIncomingMessage!)
//
//        waitForExpectations(timeout: TestUtil.waitTimeLocal) { err in
//            XCTAssertNil(err)
//        }
//
//        return optIncomingMessage!
//    }
//
//    func topMessage(byUID uid: Int) -> Message {
//        return topMessages[uid-1]
//    }
//
//    func testThreadedReferencesSentOrTrashedExistingMessage(sentOrTrashed: SentOrTrashed) {
//        func createFolder(sentOrTrashed: SentOrTrashed) -> Folder {
//            switch sentOrTrashed {
//            case .sent:
//                return Folder(name: "Sent",
//                              parent: nil,
//                              account: account,
//                              folderType: .sent)
//            case .trashed:
//                return Folder(name: "Trash",
//                              parent: nil,
//                              account: account,
//                              folderType: .trash)
//            }
//        }
//
//        FolderThreading.override(factory: ThreadAwareFolderFactory())
//        setUpTopMessages()
//
//        // create the thread base message
//        let existingFolder = createFolder(sentOrTrashed: sentOrTrashed)
//
//        existingFolder.save()
//        let sentMessage = TestUtil.createMessage(uid: TestUtil.nextUid(),
//                                                 inFolder: existingFolder)
//        sentMessage.save()
//
//        // let a top message reference that message (i.e., someone answered to our sent message)
//        let topMessageReferencingSentMessage = topMessages[0]
//        topMessageReferencingSentMessage.references.append(sentMessage.messageID)
//        topMessageReferencingSentMessage.save()
//
//        // check if it's indeed referenced
//        guard let referencedSentMessageOrig =
//            topMessageReferencingSentMessage.referencedMessages().first else {
//                XCTFail()
//                return
//        }
//        XCTAssertEqual(referencedSentMessageOrig.messageID, sentMessage.messageID)
//
//        // receive another reply to our top message
//        let incomingMessage = testIncomingMessage(
//            parameters: IncomingMessageParameters.noMessage([sentMessage], nil),
//            indexPathUpdated: indexOfTopMessage0)
//
//        // check that the incoming message indeed references our sent message
//        let incomingMessageReferencedMessages = incomingMessage.referencedMessages()
//        guard let referencedSentMessageIncoming = incomingMessageReferencedMessages.first else {
//            XCTFail()
//            return
//        }
//        XCTAssertEqual(referencedSentMessageIncoming.messageID, sentMessage.messageID)
//
//        // Will the thread be displayed correctly?
//        var isReferencingSentMessage = false
//        var isReferencingIncomingMessage = false
//        let threadMessages = topMessageReferencingSentMessage.messagesInThread()
//        for msg in threadMessages {
//            if msg.messageID == sentMessage.messageID {
//                isReferencingSentMessage = true
//            } else if msg.messageID == incomingMessage.messageID {
//                isReferencingIncomingMessage = true
//            }
//        }
//
//        switch sentOrTrashed {
//        case .sent: XCTAssertTrue(isReferencingSentMessage)
//        case .trashed: break
//        }
//
//        XCTAssertTrue(isReferencingIncomingMessage)
//    }
//
//    // MARK: - Internal - Delegate parameters
//
//    /**
//     EmailListViewModelDelegate insertion of a top message.
//     */
//    struct ExpectationTopMessageInserted {
//        let indexPath: IndexPath
//        let expectation: XCTestExpectation
//    }
//
//    /**
//     EmailListViewModelDelegate update of a top message.
//     */
//    struct ExpectationTopMessageUpdated {
//        let indexPath: IndexPath
//        let expectation: XCTestExpectation
//    }
//
//    /**
//     EmailListViewModelDelegate update of an undisplayed (child) message.
//     */
//    struct ExpectationUndiplayedMessageUpdated {
//        let message: Message
//        let expectation: XCTestExpectation
//    }
//
//    /**
//     UpdateThreadListDelegate insertion of a child message.
//     */
//    struct ExpectationChildMessageAdded {
//        let expectation: XCTestExpectation
//    }
//
//    /**
//     UpdateThreadListDelegate update of a child message.
//     */
//    struct ExpectationChildMessageUpdated {
//        let message: Message
//        let expectation: XCTestExpectation
//    }
//
//    /**
//     UpdateThreadListDelegate deletion of a child message.
//     */
//    struct ExpectationChildMessageDeleted {
//        let message: Message
//        let expectation: XCTestExpectation
//    }
//
//    /**
//     UpdateThreadListDelegate deletion of a top message.
//     */
//    struct ExpectationUpdateThreadListDelegateTopMessageDeleted {
//        let message: Message
//        let expectation: XCTestExpectation
//    }
//
//    /**
//     EmailListViewModelDelegate user-deletion of a top message
//     (both unthreaded and threaded).
//     */
//    struct ExpectationViewModelDelegateTopMessageDeleted {
//        let indexPath: IndexPath
//        let expectation: XCTestExpectation
//    }
//
//    struct ExpectationShowThreadView {
//        let expectation: XCTestExpectation
//    }
//
//    // MARK: - Internal - Delegates
//
//    class MyDisplayedMessage: DisplayedMessage {
//        var messageModel: Message?
//
//        func update(forMessage message: Message) {
//        }
//
//        func detailType() -> EmailDetailType {
//            return .single
//        }
//    }
//
//    class MyMessageSyncServiceProtocol: MessageSyncServiceProtocol {
//        func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
//        }
//
//        func requestFetchOlderMessages(inFolder folder: Folder) {
//        }
//    }
//
//    class MyEmailListViewModelDelegate: EmailListViewModelDelegate {
//        var expectationViewUpdated: XCTestExpectation?
//        var expectationUpdated: ExpectationTopMessageUpdated?
//        var expectationInserted: ExpectationTopMessageInserted?
//        var expectationUndiplayedMessageUpdated: ExpectationUndiplayedMessageUpdated?
//        var expectationTopMessageDeleted: ExpectationViewModelDelegateTopMessageDeleted?
//
//        func emailListViewModel(viewModel: EmailListViewModel,
//                                didInsertDataAt indexPaths: [IndexPath]) {
//            if let exp = expectationInserted {
//                guard
//                    indexPaths.count == 1,
//                    let indexPath = indexPaths.first else {
//                        XCTFail()
//                        return
//                }
//                XCTAssertEqual(indexPath, exp.indexPath)
//                exp.expectation.fulfill()
//            }
//        }
//
//        func emailListViewModel(viewModel: EmailListViewModel,
//                                didUpdateDataAt indexPaths: [IndexPath]) {
//            if let exp = expectationUpdated {
//                guard
//                    indexPaths.count == 1,
//                    let indexPath = indexPaths.first else {
//                        XCTFail()
//                        return
//                }
//                XCTAssertEqual(indexPath, exp.indexPath)
//                exp.expectation.fulfill()
//            }
//        }
//
//        func emailListViewModel(viewModel: EmailListViewModel,
//                                didRemoveDataAt indexPaths: [IndexPath]) {
//            if let exp = expectationTopMessageDeleted {
//                guard
//                    indexPaths.count == 1,
//                    let indexPath = indexPaths.first else {
//                        XCTFail()
//                        return
//                }
//                XCTAssertEqual(indexPath, exp.indexPath)
//                exp.expectation.fulfill()
//            }
//        }
//
//        func emailListViewModel(viewModel: EmailListViewModel,
//                                didUpdateUndisplayedMessage message: Message) {
//            if let exp = expectationUndiplayedMessageUpdated {
//                XCTAssertEqual(message, exp.message)
//                exp.expectation.fulfill()
//            }
//        }
//
//        func emailListViewModel(viewModel: EmailListViewModel,
//                                didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {
//        }
//
//        func toolbarIs(enabled: Bool) {
//        }
//
//        func showUnflagButton(enabled: Bool) {
//        }
//
//        func showUnreadButton(enabled: Bool) {
//        }
//
//        func updateView() {
//            expectationViewUpdated?.fulfill()
//        }
//    }
//
//    class MyScreenComposerProtocol: ScreenComposerProtocol {
//        var expectationShowThreadView: ExpectationShowThreadView?
//
//        func emailListViewModel(_ emailListViewModel: EmailListViewModel,
//                                requestsShowEmailViewFor message: Message) {
//            
//        }
//
//
//        func emailListViewModel(_ emailListViewModel: EmailListViewModel,
//                                requestsShowThreadViewFor message: Message) {
//                if let exp = expectationShowThreadView {
//                    exp.expectation.fulfill()
//                }
//            }
//    }
//
//    class MyUpdateThreadListDelegate: UpdateThreadListDelegate {
//        var expectationAdded: ExpectationChildMessageAdded?
//        var expectationUpdated: ExpectationChildMessageUpdated?
//        var expectationChildMessageDeleted: ExpectationChildMessageDeleted?
//
//        func deleted(message: Message) {
//            if let exp = expectationChildMessageDeleted {
//                XCTAssertEqual(message, exp.message)
//                exp.expectation.fulfill()
//            }
//        }
//
//        func updated(message: Message) {
//            if let exp = expectationUpdated {
//                XCTAssertEqual(exp.message, message)
//                exp.expectation.fulfill()
//            }
//        }
//
//        func added(message: Message) {
//            if let exp = expectationAdded {
//                exp.expectation.fulfill()
//            }
//        }
//
//        func tipDidChange(to message: Message) {
//        }
//    }
}
