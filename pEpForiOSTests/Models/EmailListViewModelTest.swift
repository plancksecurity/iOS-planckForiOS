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
    var trashFolder: Folder!
    var emailListVM : EmailListViewModel!
    var emailListMessageFolderDelegate: EmailListViewModelTestMessageFolderDelegate!
    var emailListViewModelTestDelegate: EmailListViewModelTestDelegate!

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
        trashFolder = Folder(name: "trash", parent: nil, account: folder.account, folderType: .trash)
        trashFolder.save()


    }

    func testViewModelSetUp() {
        createViewModelWithExpectations(expectedUpdateView: true)
    }

    func testCleanInitialSetup() {
        createViewModelWithExpectations(expectedUpdateView: true)
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func test10MessagesInInitialSetup() {
        _ = createMessages(number: 10, engineProccesed: true)
        createViewModelWithExpectations(expectedUpdateView: true)
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func test10MessagesThatEngineHasNotProcessedYet() {
        _ = createMessages(number: 10, engineProccesed: false)
        createViewModelWithExpectations(expectedUpdateView: true)
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func testSetSearchFilterWith0results() {
        _ = createMessages(number: 10, engineProccesed: true)
        createViewModelWithExpectations(expectedUpdateView: true)
        setNewUpdateViewExpectation()
        emailListVM.setSearchFilter(forSearchText: "blabla@blabla.com")
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func testRemoveSetSearchFilterAfter0Results() {
        _ = createMessages(number: 10, engineProccesed: true)
        createViewModelWithExpectations(expectedUpdateView: true)
        XCTAssertEqual(emailListVM.rowCount, 10)
        setNewUpdateViewExpectation()
        emailListVM.setSearchFilter(forSearchText: "blabla@blabla.com")
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(emailListVM.rowCount, 0)
        setNewUpdateViewExpectation()
        emailListVM.removeSearchFilter()
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func testSetSearchFilterAddressWith3results() {
        let textToSearch = "searchTest@mail.com"
        _ = createMessages(number: 10, engineProccesed: true)
        createMessage(inFolder: folder, from: Identity.create(address: textToSearch), tos: [folder.account.user], ccs: [], bccs: [], id: "23", engineProccesed: true).save()
        createMessage(inFolder: folder, from: Identity.create(address: textToSearch), tos: [folder.account.user], ccs: [], bccs: [], id: "24", engineProccesed: true).save()
        createMessage(inFolder: folder, from: Identity.create(address: textToSearch), tos: [folder.account.user], ccs: [], bccs: [], id: "25", engineProccesed: true).save()
        createViewModelWithExpectations(expectedUpdateView: true)
        XCTAssertEqual(emailListVM.rowCount, 13)
        setNewUpdateViewExpectation()
        emailListVM.setSearchFilter(forSearchText: "searchTest")
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(emailListVM.rowCount, 3)
    }

    func testSetSearchFilterShortMessageWith1results() {
        let textToSearch = "searchTest"
        _ = createMessages(number: 10, engineProccesed: true)
        let msg = createMessage(inFolder: folder, from: Identity.create(address: "mail@mail.com"), tos: [folder.account.user], ccs: [], bccs: [], id: "23", engineProccesed: true)
        msg.shortMessage = textToSearch
        msg.save()
        createViewModelWithExpectations(expectedUpdateView: true)
        XCTAssertEqual(emailListVM.rowCount, 11)
        setNewUpdateViewExpectation()
        emailListVM.setSearchFilter(forSearchText: textToSearch)
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(emailListVM.rowCount, 1)
    }





    //test to be thinked again
    /*func testFlagMessageFromTheList() {
        var messages : [Message] = []
        for i in 0..<1 {
            let msg = createMessage(inFolder: folder,
                                    from: folder.account.user,
                                    tos: [Identity.create(address: "mail@mail.com")],
                                    ccs: [],
                                    bccs: [],
                                    id: "\(i)", engineProccesed: true)
            msg.save()
            messages.append(msg)
        }
        createViewModelWithExpectations(expectedUpdateView: true)

        let ipToUpdated = IndexPath(row: 0, section: 0)
        //emailListVM.viewModel(for: <#T##Int#>)
        emailListVM.setFlagged(forIndexPath: ipToUpdated)
        let msgUpdated = emailListVM.message(representedByRowAt: ipToUpdated)
        XCTAssertEqual(msgUpdated?.imapFlags?.flagged, true)

    }

    func testReadMessageFromTheList() {
        var messages : [Message] = []
        for i in 0..<1 {
            let msg = createMessage(inFolder: folder,
                                    from: folder.account.user,
                                    tos: [Identity.create(address: "mail@mail.com")],
                                    ccs: [],
                                    bccs: [],
                                    id: "\(i)", engineProccesed: true)
            msg.save()
            messages.append(msg)
        }

        createViewModelWithExpectations(expectedUpdateView: true)

        let ipToUpdated = IndexPath(row: 0, section: 0)
        emailListVM.markRead(forIndexPath: ipToUpdated)
        let msgUpdated = emailListVM.message(representedByRowAt: ipToUpdated)
        XCTAssertEqual(msgUpdated?.imapFlags?.seen, true)
        let trash = Folder.by(account: self.folder.account, folderType: .trash)
        XCTAssertEqual(trash?.messageCount(), 1)

    }

    func testTrashMessageFromTheList() {
        for i in 0..<1 {
            let msg = createMessage(inFolder: folder,
                                    from: folder.account.user,
                                    tos: [Identity.create(address: "mail@mail.com")],
                                    ccs: [],
                                    bccs: [],
                                    id: "\(i)", engineProccesed: true)
            msg.save()
        }
        createViewModelWithExpectations(expectedUpdateView: true)

        let ipToUpdated = IndexPath(row: 0, section: 0)
        emailListVM.delete(forIndexPath: ipToUpdated)
        let msgUpdated = emailListVM.message(representedByRowAt: ipToUpdated)
        XCTAssertEqual(msgUpdated?.imapFlags?.deleted, true)

    }*/



    func setNewUpdateViewExpectation() {
        let updateViewExpectation = expectation(description: "UpdateViewCalled")
        emailListViewModelTestDelegate.expectationUpdateViewCalled = updateViewExpectation
    }

    func createViewModelWithExpectations(expectedUpdateView: Bool) {
        var viewModelTestDelegate : EmailListViewModelTestDelegate?

        if expectedUpdateView {
            let updateViewExpectation = expectation(description: "UpdateViewCalled")
            viewModelTestDelegate = EmailListViewModelTestDelegate(expectationUpdateViewCalled: updateViewExpectation)
        }
        guard let vmTestDelegate = viewModelTestDelegate else {
            XCTFail()
            return
        }
        self.emailListViewModelTestDelegate = viewModelTestDelegate
        setUpViewModel(emailListViewModelTestDelegate: vmTestDelegate)
        waitForExpectations(timeout: TestUtil.waitTime)
    }


    private func createMessages(number: Int, engineProccesed: Bool) -> [Message]{
        var messages : [Message] = []
        for i in 0..<number {
            let msg = createMessage(inFolder: folder,
                                    from: Identity.create(address: "mail@mail.com"),
                                    tos: [folder.account.user],
                                    ccs: [],
                                    bccs: [],
                                    id: "\(i)", engineProccesed: engineProccesed)
            messages.append(msg)
            msg.save()
        }
        return messages
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

    var expectationUpdateViewCalled: XCTestExpectation?

    init(expectationUpdateViewCalled: XCTestExpectation? = nil, expectationDidInsertDataAt: XCTestExpectation? = nil) {
        self.expectationUpdateViewCalled = expectationUpdateViewCalled
    }

    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        XCTFail()
        //fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPaths: [IndexPath]) {
        XCTFail()
        //fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
        XCTFail()
        //fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {
        XCTFail()
        //fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateUndisplayedMessage message: Message) {
        XCTFail()
        //fatalError()
    }

    func toolbarIs(enabled: Bool) {
        XCTFail()
        //fatalError()
    }

    func showUnflagButton(enabled: Bool) {
        XCTFail()
        //fatalError()
    }

    func showUnreadButton(enabled: Bool) {
        XCTFail()
        //fatalError()
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
