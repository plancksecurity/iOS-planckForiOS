//IOS-2241 DOES NOT COMPILE
////!!!crashing test:
////!!!: is WIP (IOS-1495), ignore failing tests for now.
//
////
////  EmailListViewModelTest.swift
////  pEpForiOSTests
////
////  Created by Xavier Algarra on 22/08/2018.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
//
//import XCTest
//@testable import pEpForiOS
//@testable import MessageModel
//
//class EmailListViewModelTest: CoreDataDrivenTestBase {
//    var inbox: Folder!
//    var trashFolder: Folder!
//    var outboxFolder: Folder!
//    var draftsFolder: Folder!
//    var emailListVM : EmailListViewModel!
//    fileprivate var masterViewController: TestMasterViewController!
//    var acc : Account!
//
//    override func setUp() {
//        super.setUp()
//
//        acc = cdAccount.account()
//
//        inbox = Folder(name: "inbox", parent: nil, account: acc, folderType: .inbox)
//        trashFolder = Folder(name: "trash", parent: nil, account: acc, folderType: .trash)
//        outboxFolder = Folder(name: "outbox", parent: nil, account: acc, folderType: .outbox)
//        draftsFolder = Folder(name: "drafts", parent: nil, account: acc, folderType: .drafts)
//        Session.main.commit()
//    }
//
//    override func tearDown() {
//        masterViewController = nil
//        super.tearDown()
//    }
//
//    func secondAccountSetUp() {
//        let acc2 = SecretTestData().createWorkingAccount(number: 1)
//        _ = Folder(name: "inbox", parent: nil, account: acc2, folderType: .inbox)
//        _ = Folder(name: "trash", parent: nil, account: acc2, folderType: .trash)
//        _ = Folder(name: "outbox", parent: nil, account: acc2, folderType: .outbox)
//        _ = Folder(name: "drafts", parent: nil, account: acc2, folderType: .drafts)
//        Session.main.commit()
//    }
//
//    // MARK: - Test section
//
//    func testViewModelSetUp() {
//        setupViewModel()
//        emailListVM.startMonitoring()
//    }
//
//    func testCleanInitialSetup() {
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, 0)
//    }
//
//    func test10MessagesInInitialSetup() {
//        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox, setUids: true)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, 10)
//    }
//
//    func testGetFolderName() {
//        setupViewModel()
//        XCTAssertEqual(Folder.localizedName(realName: self.inbox.realName), emailListVM.folderName)
//    }
//
//    func testGetDestructiveAction() {
//        TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: inbox)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        let destructiveAction = emailListVM.getDestructiveActtion(forMessageAt: 0)
//
//        XCTAssertEqual(destructiveAction, .trash)
//    }
//
//    func testGetDestructiveActionInOutgoingFolderIsTrash() {
//        _ = givenThereIsAMessageIn(folderType: .outbox)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        let destructiveAction = emailListVM.getDestructiveActtion(forMessageAt: 0)
//
//        XCTAssertEqual(destructiveAction, .trash)
//    }
//
//    func testShouldShowToolbarEditButtonsIfItsNotOutboxFolder() {
//        setupViewModel()
//        emailListVM.startMonitoring()
//        var showToolbarButtons = emailListVM.shouldShowToolbarEditButtons()
//        XCTAssertTrue(showToolbarButtons)
//
//        givenThereIsA(folderType: .outbox)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        showToolbarButtons = emailListVM.shouldShowToolbarEditButtons()
//        XCTAssertFalse(showToolbarButtons)
//    }
//
//    func testDefaultFilterActiveIsUnread() {
//        let messages = TestUtil.createMessages(number: 20, engineProccesed: true, inFolder: inbox)
//        messages.forEach { (msg) in
//            msg.imapFlags.seen = true
//        }
//        messages[0].imapFlags.seen = false
//        messages[2].imapFlags.seen = false
//        messages[4].imapFlags.seen = false
//        messages[6].imapFlags.seen = false
//        messages[8].imapFlags.seen = false
//
//        setupViewModel()
//        emailListVM.startMonitoring()
//
//        var unreadActive = emailListVM.unreadFilterEnabled()
//        XCTAssertFalse(unreadActive)
//
//        XCTAssertEqual(20, emailListVM.rowCount)
//        emailListVM.isFilterEnabled = true
//        XCTAssertEqual(5, emailListVM.rowCount)
//        setUpViewModelExpectations(expectationDidDeleteDataAt: true)
//        let imap = ImapFlags()
//        imap.seen = true
//        messages[0].imapFlags = imap
//
//        waitForExpectations(timeout: TestUtil.waitTime)
//
//        XCTAssertEqual(4, emailListVM.rowCount)
//        unreadActive = emailListVM.unreadFilterEnabled()
//        XCTAssertTrue(unreadActive)
//        emailListVM.isFilterEnabled = false
//        XCTAssertEqual(20, emailListVM.rowCount)
//    }
//
//    func testGetFlagAndMoreAction() {
//        let messages = TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: inbox)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        var flagAction = emailListVM.getFlagAction(forMessageAt: 0)
//        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)
//
//        XCTAssertEqual(flagAction, .flag)
//        XCTAssertEqual(moreAction, .more)
//
//        messages[0].imapFlags.flagged = true
//        messages[0].session.commit()
//
//        flagAction = emailListVM.getFlagAction(forMessageAt: 0)
//
//        XCTAssertEqual(flagAction, .unflag)
//    }
//
//    func testGetFlagAndMoreActionInOutgoingFolderIsNil() {
//        givenThereIsAMessageIn(folderType: .outbox)
//        setupViewModel()
//        emailListVM.startMonitoring()
//
//        let flagAction = emailListVM.getFlagAction(forMessageAt: 0)
//        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)
//
//        XCTAssertEqual(flagAction, nil)
//        XCTAssertEqual(moreAction, nil)
//    }
//
//    func testGetFlagAndMoreActionInDraftFolderIsNil() {
//        givenThereIsAMessageIn(folderType: .drafts)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        let flagAction = emailListVM.getFlagAction(forMessageAt: 0)
//        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)
//
//        XCTAssertEqual(flagAction, nil)
//        XCTAssertEqual(moreAction, nil)
//    }
//
//    func testAccountExists() {
//        setupViewModel()
//        emailListVM.startMonitoring()
//        var noAccounts = emailListVM.showLoginView
//
//        XCTAssertFalse(noAccounts)
//
//        moc.delete(cdAccount)
//        setupViewModel()
//        noAccounts = emailListVM.showLoginView
//
//        XCTAssertTrue(noAccounts)
//    }
//
//    // MARK: - Search section
//
//    func testSetSearchFilterWith0results() {
//        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        emailListVM.setSearch(forSearchText: "blabla@blabla.com")
//        XCTAssertEqual(emailListVM.rowCount, 0)
//    }
//
//    func testRemoveSearchFilterAfter0Results() {
//        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, 10)
//        emailListVM.setSearch(forSearchText: "blabla@blabla.com")
//        XCTAssertEqual(emailListVM.rowCount, 0)
//        emailListVM.removeSearch()
//        XCTAssertEqual(emailListVM.rowCount, 10)
//    }
//
//    func testSetSearchFilterAddressWith3results() {
//        let textToSearch = "searchTest@mail.com"
//        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
//        TestUtil.createMessage(inFolder: inbox,
//                               from: Identity(address: textToSearch),
//                               tos: [inbox.account.user],
//                               uid: 666).session.commit()
//        TestUtil.createMessage(inFolder: inbox,
//                               from: Identity(address: textToSearch),
//                               tos: [inbox.account.user],
//                               uid: 667).session.commit()
//        TestUtil.createMessage(inFolder: inbox,
//                               from: Identity(address: textToSearch),
//                               tos: [inbox.account.user],
//                               uid: 668).session.commit()
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, 13)
//        emailListVM.setSearch(forSearchText: textToSearch)
//        XCTAssertEqual(emailListVM.rowCount, 3)
//    }
//
//    func testSetSearchFilterShortMessageWith1results() {
//        let textToSearch = "searchTest"
//        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
//        TestUtil.createMessage(inFolder: inbox,
//                               from: Identity(address: "mail@mail.com"),
//                               tos: [inbox.account.user],
//                               shortMessage: textToSearch,
//                               uid: 666).session.commit()
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, 11)
//        emailListVM.setSearch(forSearchText: textToSearch)
//        XCTAssertEqual(emailListVM.rowCount, 1)
//    }
//
//    func testSetSearchMultipleSitesMatchInMessagesWith2results() {
//        let textToSearch = "searchTest"
//        let longText = "bla " + textToSearch + " bla"
//        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
//        TestUtil.createMessage(inFolder: inbox,
//                               from: Identity(address: "mail@mail.com"),
//                               shortMessage: textToSearch,
//                               uid: 666).session.commit()
//        TestUtil.createMessage(inFolder: inbox,
//                               from: Identity(address: "mail@mail.com"),
//                               tos: [inbox.account.user],
//                               longMessage: longText,
//                               uid: 667).session.commit()
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, 12)
//        emailListVM.setSearch(forSearchText: textToSearch)
//        XCTAssertEqual(emailListVM.rowCount, 2)
//    }
//
//
//    // MARK: - cell for row
//    /*
//     func testIndexFromMessage() {
//     let msgs = TestUtil.createMessages(number: 10, inFolder: folder)
//     setupViewModel()
//     emailListVM.startMonitoring()
//     var index = emailListVM.index(of: msgs[0])
//     XCTAssertEqual(index, 9)
//     index = emailListVM.index(of: msgs[9])
//     XCTAssertEqual(index, 0)
//     }*/
//
//    func testViewModel() {
//        let msg = TestUtil.createMessage(inFolder: inbox, from: inbox.account.user, uid: 1)
//        msg.session.commit()
//        setupViewModel()
//        emailListVM.startMonitoring()
//        let indexOfTheOneAndOnlyMsg = 0
//        let vm = emailListVM.viewModel(for: indexOfTheOneAndOnlyMsg)
//        XCTAssertEqual(vm?.message, msg)
//        XCTAssertEqual(vm?.subject, msg.shortMessage)
//    }
//
//    //    func testSetUpFilterViewModel() {
//    //        var filterEnabled = false
//    //        setupViewModel()
//    //        XCTAssertEqual(filterEnabled, emailListVM.isFilterEnabled)
//    //        filterEnabled = true
//    //        setUpViewModelExpectations(expectedUpdateView: true)
//    //        emailListVM.isFilterEnabled = filterEnabled
//    //        waitForExpectations(timeout: TestUtil.waitTime)
//    //        XCTAssertEqual(filterEnabled, emailListVM.isFilterEnabled)
//    //    }
//
//    func testNewMessageReceivedAndDisplayedInTheCorrectPosition() {
//        var messages = TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, messages.count)
//        setUpViewModelExpectations(expectationDidInsertDataAt: true)
//        let msg = TestUtil.createMessage(inFolder: inbox, from: inbox.account.user)
//        messages.append(msg)
//        Session.main.commit()
//        waitForExpectations(timeout: TestUtil.waitTime)
//        XCTAssertEqual(emailListVM.rowCount, messages.count)
//
//        guard let firstMsgVM = emailListVM.viewModel(for: 0) else {
//            XCTFail()
//            return
//        }
//        XCTAssertEqual(firstMsgVM.message, msg)
//
//        // Create a message that must not be shown
//        TestUtil.createMessage(inFolder: trashFolder, from: inbox.account.user)
//        Session.main.commit()
//        XCTAssertEqual(emailListVM.rowCount, messages.count)
//    }
//
//    func testNewMessageUpdateReceivedAndDisplayed() {
//        var messages = TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
//        Session.main.commit()
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, messages.count)
//        waitForExpectations(timeout: TestUtil.waitTime) //!!!: rm? Which expectation to wait for?
//
//        let numFlagged = 2
//        for i in 0..<numFlagged {
//            messages[i].imapFlags.flagged = true
//        }
//        Session.main.commit()
//
//        XCTAssertEqual(emailListVM.rowCount, messages.count - numFlagged)
//    }
//
//    func testNewMessageDeleteReceivedAndDisplayed() {
//        var messages = TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
//        Session.main.commit()
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(emailListVM.rowCount, messages.count)
//
//
//        setUpViewModelExpectations(expectationDidDeleteDataAt: true)
//
//        let numDelete = 1
//        for i in 0..<numDelete {
//            messages[i].cdMessage()?.imapFields().localFlags?.flagDeleted = true
//        }
//        Session.main.commit()
//        waitForExpectations(timeout: TestUtil.waitTime)
//
//        XCTAssertEqual(emailListVM.rowCount, messages.count - numDelete)
//    }
//
//    func testgetMoveToFolderViewModel() {
//        TestUtil.createMessages(number: 4, inFolder: inbox)
//        let index: [IndexPath] = [IndexPath(row: 0, section: 1),
//                                  IndexPath(row: 0, section: 2)]
//        setupViewModel()
//        emailListVM.startMonitoring()
//
//        let accountvm = emailListVM.getMoveToFolderViewModel(forSelectedMessages: index)
//
//        let postMessages = accountvm!.items[0].messages
//        XCTAssertEqual(index.count, postMessages.count)
//    }
//
//    func testMessageInOutboxAreNonEditableAndNonSelectable() {
//        TestUtil.createMessage(uid: 1, inFolder: outboxFolder)
//        moc.saveAndLogErrors()
//        setupViewModel(forfolder: outboxFolder)
//        emailListVM.startMonitoring()
//        XCTAssertEqual(1, emailListVM.rowCount)
//        let notEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
//        XCTAssertFalse(notEditable)
//        let notSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
//        XCTAssertFalse(notSelectable)
//    }
//
//    func testMessageInInboxAreOnlySelectable() {
//        TestUtil.createMessage(uid: 1, inFolder: inbox)
//        moc.saveAndLogErrors()
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertEqual(1, emailListVM.rowCount)
//        let isEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
//        XCTAssertFalse(isEditable)
//        let isSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
//        XCTAssertTrue(isSelectable)
//    }
//
//    func testMessageInDraftsAreEditableAndSelectable() {
//        TestUtil.createMessage(uid: 1, inFolder: draftsFolder)
//        moc.saveAndLogErrors()
//        setupViewModel(forfolder: draftsFolder)
//        emailListVM.startMonitoring()
//        XCTAssertEqual(1, emailListVM.rowCount)
//        let isEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
//        XCTAssertTrue(isEditable)
//        let isSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
//        XCTAssertTrue(isSelectable)
//    }
//
//    func testComposePrefilledFromAccountIsCorrectlySettedWithOnlyOneAccount() {
//        let expectedFrom = inbox.account.user
//        setupViewModel()
//        let composeVM = emailListVM.composeViewModelForNewMessage()
//        XCTAssertEqual(composeVM.state.from, expectedFrom)
//    }
//
//    func testComposePrefilledFromAccountIsDefaultAccountFromUnifiedIboxWithMultipleAccounts() {
//        let expectedFrom = inbox.account.user
//        secondAccountSetUp()
//        AppSettings.shared.defaultAccount = acc.user.address
//        setupViewModel(forfolder: UnifiedInbox())
//        let composeVM = emailListVM.composeViewModelForNewMessage()
//        XCTAssertEqual(composeVM.state.from, expectedFrom)
//    }
//
//    func testComposePrefilledFromAccountIsFolderAccountFromSpecificFolderWithMultipleAccounts() {
//        let expectedFrom = inbox.account.user
//        secondAccountSetUp()
//        setupViewModel(forfolder: inbox)
//        let composeVM = emailListVM.composeViewModelForNewMessage()
//        XCTAssertEqual(composeVM.state.from, expectedFrom)
//    }
//
//    func testPullToRefreshAction() {
//
//        let pullToRefreshExpectation = expectation(description: "pullToRefreshExpectation")
//        let message = TestUtil.createMessage(uid: 0, inFolder: inbox)
//        message.pEpProtected = false
//        moc.saveAndLogErrors()
//        let uuid = message.uuid
//        TestUtil.syncAndWait(testCase: self)
//        let cdMessages = CdMessage.all()
//        for message in cdMessages! {
//            moc.delete(message)
//        }
//        moc.saveAndLogErrors()
//        setupViewModel(forfolder: inbox)
//        emailListVM.startMonitoring()
//        setUpViewModelExpectations(expectationDidInsertDataAt: true)
//        emailListVM.fetchNewMessages() {
//            pullToRefreshExpectation.fulfill()
//        }
//        waitForExpectations(timeout: TestUtil.waitTime)
//        let messagesAfterFetch = emailListVM.message(representedByRowAt: IndexPath(item: 0, section: 0))//get the first message which is te one we append
//        XCTAssertEqual(messagesAfterFetch?.uuid, uuid)
//        XCTAssertNotEqual(messagesAfterFetch?.uid, Message.uidNeedsAppend)
//    }
//
//}
//
/// MARK: - HELPER
//
//extension EmailListViewModelTest {
//
//    private func setUpViewModel(forFolder folder: DisplayableFolderProtocol,
//                                masterViewController: TestMasterViewController) {
//        self.emailListVM = EmailListViewModel(emailListViewModelDelegate: masterViewController,
//                                              folderToShow: folder)
//    }
//
//    private func setupViewModel(forfolder internalFolder: DisplayableFolderProtocol? = nil) {
//        let folderToUse: DisplayableFolderProtocol
//        if internalFolder == nil {
//            folderToUse = inbox
//        } else {
//            folderToUse = internalFolder!
//        }
//        createViewModelWithExpectations(forFolder: folderToUse, expectedUpdateView: true)
//    }
//
//    /*private func setSearchFilter(text: String) {
//     setNewUpdateViewExpectation()
//     emailListVM.setSearchFilter(forSearchText: text)
//     waitForExpectations(timeout: TestUtil.waitTime)
//     }
//
//     private func removeSearchFilter() {
//     setNewUpdateViewExpectation()
//     emailListVM.removeSearchFilter()
//     waitForExpectations(timeout: TestUtil.waitTime)
//     }*/
//
//    private func setNewUpdateViewExpectation() {
//        let updateViewExpectation = expectation(description: "UpdateViewCalled")
//        masterViewController.expectationUpdateViewCalled = updateViewExpectation
//    }
//
//    private func createViewModelWithExpectations(forFolder folder: DisplayableFolderProtocol, expectedUpdateView: Bool) {
//        let viewModelTestDelegate = TestMasterViewController()
//        masterViewController = viewModelTestDelegate
//        setUpViewModel(forFolder: folder, masterViewController: viewModelTestDelegate)
//    }
//
//    private func setUpViewModelExpectations(expectedUpdateView: Bool = false,
//                                            expectationDidInsertDataAt: Bool = false,
//                                            expectationDidUpdateDataAt: Bool = false,
//                                            expectationDidDeleteDataAt: Bool = false ) {
//        var expectationUpdateViewCalled: XCTestExpectation?
//        if expectedUpdateView {
//            expectationUpdateViewCalled = expectation(description: "UpdateViewCalled")
//        }
//
//        var excpectationDidInsertDataAtCalled: XCTestExpectation?
//        if expectationDidInsertDataAt {
//            excpectationDidInsertDataAtCalled =
//                expectation(description: "excpectationDidInsertDataAtCalled")
//        }
//
//        var excpectationDidUpdateDataAtCalled: XCTestExpectation?
//        if expectationDidUpdateDataAt {
//            excpectationDidUpdateDataAtCalled =
//                expectation(description: "excpectationDidUpdateDataAtCalled")
//        }
//
//        var excpectationDidDeleteDataAtCalled: XCTestExpectation?
//        if expectationDidDeleteDataAt {
//            excpectationDidDeleteDataAtCalled =
//                expectation(description: "excpectationDidInsertDataAtCalled")
//        }
//
//        masterViewController =
//            TestMasterViewController(expectationUpdateView: expectationUpdateViewCalled,
//                                     expectationDidInsertDataAt: excpectationDidInsertDataAtCalled,
//                                     expectationDidUpdateDataAt: excpectationDidUpdateDataAtCalled,
//                                     expectationDidRemoveDataAt: excpectationDidDeleteDataAtCalled)
//        emailListVM.emailListViewModelDelegate = masterViewController
//    }
//
//    private func getSafeLastLookAt() -> Date {
//        guard let safeLastLookedAt = inbox?.lastLookedAt as Date? else {
//            XCTFail()
//            return Date()
//        }
//        return safeLastLookedAt
//    }
//
//    private func givenThereIsA(folderType: FolderType) {
//        inbox = Folder(name: "-", parent: inbox, account: account, folderType: folderType)
//        inbox.session.commit()
//    }
//
//    @discardableResult private func givenThereIsAMessageIn(folderType: FolderType) -> Message? {
//        givenThereIsA(folderType: folderType)
//        let msg = TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: inbox).first
//        Session.main.commit()
//        return msg
//    }
//}
//
//private class TestMasterViewController: EmailListViewModelDelegate {
//    var expectationUpdateViewCalled: XCTestExpectation?
//    var excpectationDidInsertDataAtCalled: XCTestExpectation?
//    var expectationDidUpdateDataAtCalled: XCTestExpectation?
//    var expectationDidRemoveDataAtCalled: XCTestExpectation?
//
//    init(expectationUpdateView: XCTestExpectation? = nil,
//         expectationDidInsertDataAt: XCTestExpectation? = nil,
//         expectationDidUpdateDataAt: XCTestExpectation? = nil,
//         expectationDidRemoveDataAt: XCTestExpectation? = nil) {
//        self.expectationUpdateViewCalled = expectationUpdateView
//        self.excpectationDidInsertDataAtCalled = expectationDidInsertDataAt
//        self.expectationDidUpdateDataAtCalled = expectationDidUpdateDataAt
//        self.expectationDidRemoveDataAtCalled = expectationDidRemoveDataAt
//    }
//
//    func willReceiveUpdates(viewModel: EmailListViewModel) {
//        //not yet defined
//    }
//
//    func allUpdatesReceived(viewModel: EmailListViewModel) {
//        //not yet defined
//    }
//
//    func reloadData(viewModel: EmailListViewModel) {
//        //not yet defined
//    }
//
//
//    func emailListViewModel(viewModel: EmailListViewModel,
//                            didInsertDataAt indexPaths: [IndexPath]) {
//        if let excpectationDidInsertDataAtCalled = excpectationDidInsertDataAtCalled {
//            excpectationDidInsertDataAtCalled.fulfill()
//        } else {
//            XCTFail()
//        }
//    }
//
//    func emailListViewModel(viewModel: EmailListViewModel,
//                            didUpdateDataAt indexPaths: [IndexPath]) {
//        if let expectationDidUpdateDataAtCalled = expectationDidUpdateDataAtCalled {
//            expectationDidUpdateDataAtCalled.fulfill()
//        } else {
//            XCTFail()
//        }
//    }
//
//    func emailListViewModel(viewModel: EmailListViewModel,
//                            didRemoveDataAt indexPaths: [IndexPath]) {
//        if let expectationDidRemoveDataAtCalled = expectationDidRemoveDataAtCalled {
//            expectationDidRemoveDataAtCalled.fulfill()
//        } else {
//            XCTFail()
//        }
//    }
//
//    func emailListViewModel(viewModel: EmailListViewModel,
//                            didMoveData atIndexPath: IndexPath,
//                            toIndexPath: IndexPath) {
//        XCTFail()
//    }
//    //not exist anymore
//    func emailListViewModel(viewModel: EmailListViewModel,
//                            didUpdateUndisplayedMessage message: Message) {
//        XCTFail()
//    }
//
//    func toolbarIs(enabled: Bool) {
//        XCTFail()
//    }
//
//    func showUnflagButton(enabled: Bool) {
//        XCTFail()
//    }
//
//    func showUnreadButton(enabled: Bool) {
//        XCTFail()
//    }
//
//    //not exist anymore
//    func updateView() {
//        if let expectationUpdateViewCalled = expectationUpdateViewCalled {
//            expectationUpdateViewCalled.fulfill()
//        } else {
//            XCTFail()
//        }
//    }
//}
//
////class TestServer: MessageQueryResults {
////    var results: [Message] = [Message]()
////
////    required init(withFolder folder: Folder) {
////        super.init(withDisplayableFolder: folder)
////    }
////
////
////    override var count: Int {
////        return results.count
////    }
////
////    override subscript(index: Int) -> Message {
////        return results[index]
////    }
////
////    override func startMonitoring() throws {
////
////    }
////
////    func insertData(message: Message) {
////        results.append(message)
////        let ip = IndexPath(row: results.firstIndex(of: message)!, section: 0)
////        delegate?.didInsert(indexPath: ip)
////    }
////
////    func updateData(message: Message) {
////        let ip = IndexPath(row: results.firstIndex(of: message)!, section: 0)
////        delegate?.didUpdate(indexPath: ip)
////    }
////
////    func deleteData(message: Message) {
////        let index = results.firstIndex(of: message)
////        results.remove(at: index!)
////        let ip = IndexPath(row: index!, section: 0)
////        delegate?.didDelete(indexPath: ip)
////    }
////
////    func insertMessagesWithoutDelegate(messages: [Message]) {
////        results.append(contentsOf: messages)
////    }
////}
