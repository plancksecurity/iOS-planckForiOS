//
//  EmailListViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 22/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//


import XCTest
@testable import pEpForiOS
import MessageModel

class EmailListViewModelTest: CoreDataDrivenTestBase {
    var folder: Folder!
    var emailListVM : EmailListViewModel!
    var emailListMessageFolderDelegate: EmailListViewModelTestMessageFolderDelegate!

    fileprivate func setUpViewModel(emailListViewModelTestDelegate: EmailListViewModelTestDelegate) {
        let msgsyncservice = MessageSyncService()
        self.emailListVM = EmailListViewModel(emailListViewModelDelegate: emailListViewModelTestDelegate, messageSyncService: msgsyncservice, folderToShow: folder)

    }

    fileprivate func setUpMessageFolderDelegate() {
        self.emailListMessageFolderDelegate = EmailListViewModelTestMessageFolderDelegate(messageFolderDelegate: emailListVM)
    }

    /** this set up a view model with one account and one folder saved **/
    override func setUp() {
        super.setUp()

        let acc = cdAccount.account()

        folder = Folder(name: "inbox", parent: nil, account: acc, folderType: .inbox)
        folder.save()


    }

    func testViewModelSetUp() {
        createViewModelWithExpectations(expectedUpdateView: true, expectedDidInsertData: false)
    }

    func testCleanInitialSetup() {
        createViewModelWithExpectations(expectedUpdateView: true, expectedDidInsertData: false)
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func test10MessagesInInitialSetup() {
        for i in 0..<10 {
            let msg = createMessage(inFolder: folder,
                          from: folder.account.user,
                          tos: [Identity.create(address: "mail@mail.com")],
                          ccs: [],
                          bccs: [],
                          id: "\(i)", engineProccesed: true)
            msg.save()
        }
        createViewModelWithExpectations(expectedUpdateView: true, expectedDidInsertData: false)
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func test10MessagesThatEngineHasNotProcessedYet() {
        for i in 0..<10 {
            let msg = createMessage(inFolder: folder,
                                    from: folder.account.user,
                                    tos: [Identity.create(address: "mail@mail.com")],
                                    ccs: [],
                                    bccs: [],
                                    id: "\(i)", engineProccesed: false)
            msg.save()
        }
        createViewModelWithExpectations(expectedUpdateView: true, expectedDidInsertData: false)
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func createViewModelWithExpectations(expectedUpdateView: Bool, expectedDidInsertData: Bool) {
        var viewModelTestDelegate : EmailListViewModelTestDelegate?

        if expectedUpdateView {
            let updateViewExpectation = expectation(description: "UpdateViewCalled")
            viewModelTestDelegate = EmailListViewModelTestDelegate(expectationUpdateViewCalled: updateViewExpectation)
        }
        if expectedDidInsertData {
            let didInsertDataExpectation = expectation(description: "didInsertData")
            viewModelTestDelegate = EmailListViewModelTestDelegate(expectationDidInsertDataAt: didInsertDataExpectation)
        }
        guard let vmTestDelegate = viewModelTestDelegate else {
            XCTFail()
            return
        }
        setUpViewModel(emailListViewModelTestDelegate: vmTestDelegate)
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    private func createMessage(inFolder folder: Folder,
                                       from: Identity,
                                       tos: [Identity],
                                       ccs: [Identity],
                                       bccs: [Identity],
                                       id: String,
                                       engineProccesed: Bool) -> Message {
        let msg = Message(uuid: MessageID.generate(), parentFolder: folder)
        msg.from = from
        msg.to = tos
        msg.cc = ccs
        msg.bcc = bccs
        let id = id
        msg.shortMessage = id
        msg.longMessage = id
        let minute:TimeInterval = 60.0
        msg.sent = Date()
        msg.received = Date(timeIntervalSinceNow: minute)
        if engineProccesed {
            msg.pEpRatingInt = Int(PEP_rating_unreliable.rawValue)
        }
        return msg
    }

}

class EmailListViewModelTestDelegate: EmailListViewModelDelegate {

    let expectationUpdateViewCalled: XCTestExpectation?
    let expectationDidInsertDataAt: XCTestExpectation?

    init(expectationUpdateViewCalled: XCTestExpectation? = nil, expectationDidInsertDataAt: XCTestExpectation? = nil) {
        self.expectationUpdateViewCalled = expectationUpdateViewCalled
        self.expectationDidInsertDataAt = expectationDidInsertDataAt
    }

    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        if let expectationDidInsertDataAt = expectationUpdateViewCalled {
            expectationDidInsertDataAt.fulfill()
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPaths: [IndexPath]) {
        fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
        fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {
        fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateUndisplayedMessage message: Message) {
        fatalError()
    }

    func toolbarIs(enabled: Bool) {
        fatalError()
    }

    func showUnflagButton(enabled: Bool) {
        fatalError()
    }

    func showUnreadButton(enabled: Bool) {
        fatalError()
    }

    func updateView() {
        if let expectationUpdateViewCalled = expectationUpdateViewCalled {
            expectationUpdateViewCalled.fulfill()
        }
    }
}

class EmailListViewModelTestMessageFolderDelegate {
    var messageFolderDelegate : MessageFolderDelegate
    init(messageFolderDelegate: MessageFolderDelegate) {
        self.messageFolderDelegate = messageFolderDelegate
    }
    func insertData(message: Message) {

        self.messageFolderDelegate.didCreate(messageFolder: message)
    }
}

//let msg = Message(uuid: "uuid", parentFolder: fol)
