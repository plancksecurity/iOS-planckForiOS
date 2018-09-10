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

    func setupViewModel() {
        createViewModelWithExpectations(expectedUpdateView: true)
    }

    func setSearchFilter(text: String) {
        setNewUpdateViewExpectation()
        emailListVM.setSearchFilter(forSearchText: text)
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func removeSearchFilter() {
        setNewUpdateViewExpectation()
        emailListVM.removeSearchFilter()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    //mark: Setup section

    func testViewModelSetUp() {
        setupViewModel()
    }

    func testCleanInitialSetup() {
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func test10MessagesInInitialSetup() {
        _ = createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func test10MessagesThatEngineHasNotProcessedYet() {
        _ = createMessages(number: 10, engineProccesed: false, inFolder: folder)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func testUnifiedInbox() {
        setupViewModel()
    }

    //mark: Search section

    func testSetSearchFilterWith0results() {
        _ = createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        setSearchFilter(text: "blabla@blabla.com")
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    fileprivate

    func testRemoveSetSearchFilterAfter0Results() {
        _ = createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 10)
        setSearchFilter(text: "blabla@blabla.com")
        XCTAssertEqual(emailListVM.rowCount, 0)
        removeSearchFilter()
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func testSetSearchFilterAddressWith3results() {
        let textToSearch = "searchTest@mail.com"
        _ = createMessages(number: 10, engineProccesed: true, inFolder: folder)
        createMessage(inFolder: folder,
                      from: Identity.create(address: textToSearch),
                      tos: [folder.account.user]).save()
        createMessage(inFolder: folder,
                      from: Identity.create(address: textToSearch),
                      tos: [folder.account.user]).save()
        createMessage(inFolder: folder,
                      from: Identity.create(address: textToSearch),
                      tos: [folder.account.user]).save()
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 13)
        setSearchFilter(text: "searchTest")
        XCTAssertEqual(emailListVM.rowCount, 3)
    }

    func testSetSearchFilterShortMessageWith1results() {
        let textToSearch = "searchTest"
        _ = createMessages(number: 10, engineProccesed: true, inFolder: folder)
        createMessage(inFolder: folder,
                      from: Identity.create(address: "mail@mail.com"),
                      tos: [folder.account.user],
                      shortMessage: textToSearch).save()
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 11)
        setSearchFilter(text: textToSearch)
        XCTAssertEqual(emailListVM.rowCount, 1)
    }

    func testSetSearchMultipleSitesMatchInMessagesWith2results() {
        let textToSearch = "searchTest"
        let longText = "bla " + textToSearch + " bla"
        _ = createMessages(number: 10, engineProccesed: true, inFolder: folder)
        createMessage(inFolder: folder,
                      from: Identity.create(address: "mail@mail.com"),
                      shortMessage: textToSearch).save()
        createMessage(inFolder: folder,
                      from: Identity.create(address: "mail@mail.com"),
                      tos: [folder.account.user],
                      longMessage: longText).save()
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 12)
        setSearchFilter(text: textToSearch)
        XCTAssertEqual(emailListVM.rowCount, 2)
    }

    //thread view nos is totaly disabled that means always false
    func testCheckIfSettingsChanged() {
        setupViewModel()
        XCTAssertFalse(AppSettings.threadedViewEnabled)
        AppSettings.threadedViewEnabled = true
        XCTAssertFalse(emailListVM.checkIfSettingsChanged())
    }

    //mark: cell for row

    func testIndexFromMessage() {
        let msgs = createMessages(number: 10, inFolder: folder)
        setupViewModel()
        var index = emailListVM.index(of: msgs[0])
        XCTAssertEqual(index, 9)
        index = emailListVM.index(of: msgs[9])
        XCTAssertEqual(index, 0)
    }

    func testViewModel() {
        let msg = createMessage(inFolder: folder, from: folder.account.user)
        msg.save()
        setupViewModel()
        let index = emailListVM.index(of: msg)
        guard let ind = index else {
            XCTFail()
            return
        }
        let vm = emailListVM.viewModel(for: ind)
        XCTAssertEqual(vm?.message(), msg)
        XCTAssertEqual(vm?.subject, msg.shortMessage)
    }









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

    private func createMessages(number: Int,
                                engineProccesed: Bool = true,
                                inFolder: Folder) -> [Message]{
        var messages : [Message] = []
        for _ in 0..<number {
            let msg = createMessage(inFolder: inFolder,
                                    from: Identity.create(address: "mail@mail.com"),
                                    tos: [inFolder.account.user],
                                    engineProccesed: engineProccesed)
            messages.append(msg)
            msg.save()
        }
        return messages
    }

    private func createMessage(inFolder folder: Folder,
                                       from: Identity,
                                       tos: [Identity] = [],
                                       ccs: [Identity] = [],
                                       bccs: [Identity] = [],
                                       engineProccesed: Bool = true,
                                       shortMessage: String = "",
                                       longMessage: String = "") -> Message {
        let msg = Message(uuid: MessageID.generate(), parentFolder: folder)
        msg.from = from
        msg.to = tos
        msg.cc = ccs
        msg.bcc = bccs
        msg.messageID = MessageID.generate()
        msg.shortMessage = shortMessage
        msg.longMessage = longMessage
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
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPaths: [IndexPath]) {
        XCTFail()
    }

    func emailListViewModel(viewModel: EmailListViewModel,
                            didChangeSeenStateForDataAt indexPaths: [IndexPath]) {
        XCTFail("Currently unused in tests. Should not be called")
    }

    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
        XCTFail()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {
        XCTFail()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateUndisplayedMessage message: Message) {
        XCTFail()
    }

    func toolbarIs(enabled: Bool) {
        XCTFail()
    }

    func showUnflagButton(enabled: Bool) {
        XCTFail()
    }

    func showUnreadButton(enabled: Bool) {
        XCTFail()
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
