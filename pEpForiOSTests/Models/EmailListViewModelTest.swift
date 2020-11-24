//
//  EmailListViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 22/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class EmailListViewModelTest: AccountDrivenTestBase {
    var inbox: Folder!
    var trashFolder: Folder!
    var outboxFolder: Folder!
    var draftsFolder: Folder!
    var emailListVM : EmailListViewModel!
    fileprivate var masterViewController: TestMasterViewController!

    override func setUp() {
        super.setUp()

        inbox = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        trashFolder = Folder(name: "trash", parent: nil, account: account, folderType: .trash)
        outboxFolder = Folder(name: "outbox", parent: nil, account: account, folderType: .outbox)
        draftsFolder = Folder(name: "drafts", parent: nil, account: account, folderType: .drafts)
        Session.main.commit()
    }

    override func tearDown() {
        masterViewController = nil
        super.tearDown()
    }

    func secondAccountSetUp() {
        let acc2 = TestData().createWorkingAccount(number: 1)
        _ = Folder(name: "inbox", parent: nil, account: acc2, folderType: .inbox)
        _ = Folder(name: "trash", parent: nil, account: acc2, folderType: .trash)
        _ = Folder(name: "outbox", parent: nil, account: acc2, folderType: .outbox)
        _ = Folder(name: "drafts", parent: nil, account: acc2, folderType: .drafts)
        Session.main.commit()
    }

    // MARK: - Test section

    func testViewModelSetUp() {
        setupViewModel()
        emailListVM.startMonitoring()
    }

    func testCleanInitialSetup() {
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func test10MessagesInInitialSetup() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox, setUids: true)
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func testGetFolderName() {
        setupViewModel()
        XCTAssertEqual(Folder.localizedName(realName: self.inbox.realName), emailListVM.folderName)
    }

    func testShouldShowToolbarEditButtonsIfItsNotOutboxFolder() {
        setupViewModel()
        emailListVM.startMonitoring()
        var showToolbarButtons = emailListVM.shouldShowToolbarEditButtons
        XCTAssertTrue(showToolbarButtons)

        givenThereIsA(folderType: .outbox)
        setupViewModel()
        emailListVM.startMonitoring()
        showToolbarButtons = emailListVM.shouldShowToolbarEditButtons
        XCTAssertFalse(showToolbarButtons)
    }

    func testAccountExists() {
        setupViewModel()
        emailListVM.startMonitoring()
        var noAccounts = emailListVM.showLoginView

        XCTAssertFalse(noAccounts)

        account.delete()
        setupViewModel()
        noAccounts = emailListVM.showLoginView

        XCTAssertTrue(noAccounts)
    }

    // MARK: - Search section

    func testSetSearchFilterWith0results() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
        setupViewModel()
        emailListVM.startMonitoring()
        emailListVM.handleSearchTermChange(newSearchTerm: "blabla@blabla.com")
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func testRemoveSearchFilterAfter0Results() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 10)
        emailListVM.handleSearchTermChange(newSearchTerm: "blabla@blabla.com")
        XCTAssertEqual(emailListVM.rowCount, 0)
        emailListVM.handleSearchTermChange(newSearchTerm: "")
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func testSetSearchFilterAddressWith3results() {
        let textToSearch = "searchTest@mail.com"
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
        TestUtil.createMessage(inFolder: inbox,
                               from: Identity(address: textToSearch),
                               tos: [inbox.account.user],
                               uid: 666).session.commit()
        TestUtil.createMessage(inFolder: inbox,
                               from: Identity(address: textToSearch),
                               tos: [inbox.account.user],
                               uid: 667).session.commit()
        TestUtil.createMessage(inFolder: inbox,
                               from: Identity(address: textToSearch),
                               tos: [inbox.account.user],
                               uid: 668).session.commit()
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 13)
        emailListVM.handleSearchTermChange(newSearchTerm: textToSearch)
        XCTAssertEqual(emailListVM.rowCount, 3)
    }

    func testSetSearchFilterShortMessageWith1results() {
        let textToSearch = "searchTest"
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
        TestUtil.createMessage(inFolder: inbox,
                               from: Identity(address: "mail@mail.com"),
                               tos: [inbox.account.user],
                               shortMessage: textToSearch,
                               uid: 666).session.commit()
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 11)
        emailListVM.handleSearchTermChange(newSearchTerm: textToSearch)
        XCTAssertEqual(emailListVM.rowCount, 1)
    }

    func testSetSearchMultipleSitesMatchInMessagesWith2results() {
        let textToSearch = "searchTest"
        let longText = "bla " + textToSearch + " bla"
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: inbox)
        TestUtil.createMessage(inFolder: inbox,
                               from: Identity(address: "mail@mail.com"),
                               shortMessage: textToSearch,
                               uid: 666).session.commit()
        TestUtil.createMessage(inFolder: inbox,
                               from: Identity(address: "mail@mail.com"),
                               tos: [inbox.account.user],
                               longMessage: longText,
                               uid: 667).session.commit()
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 12)
        emailListVM.handleSearchTermChange(newSearchTerm: textToSearch)
        XCTAssertEqual(emailListVM.rowCount, 2)
    }


    // MARK: - cell for row

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

    func testgetMoveToFolderViewModel() {
        TestUtil.createMessages(number: 4, inFolder: inbox)
        let index: [IndexPath] = [IndexPath(row: 0, section: 1),
                                  IndexPath(row: 0, section: 2)]
        setupViewModel()
        emailListVM.startMonitoring()

        let accountvm = emailListVM.getMoveToFolderViewModel(forSelectedMessages: index)

        let postMessages = accountvm!.items[0].messages
        XCTAssertEqual(index.count, postMessages.count)
    }

    func testMessageInOutboxAreNonEditableAndNonSelectable() {
        let msg = TestUtil.createMessage(uid: 1, inFolder: outboxFolder)
        msg.session.commit()
        setupViewModel(forfolder: outboxFolder)
        emailListVM.startMonitoring()
        XCTAssertEqual(1, emailListVM.rowCount)
        let notEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(notEditable)
        let notSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(notSelectable)
    }

    func testMessageInInboxAreOnlySelectable() {
        let msg = TestUtil.createMessage(uid: 1, inFolder: inbox)
        msg.session.commit()
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(1, emailListVM.rowCount)
        let isEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(isEditable)
        let isSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(isSelectable)
    }

    func testMessageInDraftsAreEditableAndSelectable() {
        let msg = TestUtil.createMessage(uid: 1, inFolder: draftsFolder)
        msg.session.commit()
        setupViewModel(forfolder: draftsFolder)
        emailListVM.startMonitoring()
        XCTAssertEqual(1, emailListVM.rowCount)
        let isEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(isEditable)
        let isSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(isSelectable)
    }

    func testComposePrefilledFromAccountIsCorrectlySettedWithOnlyOneAccount() {
        let expectedFrom = inbox.account.user
        setupViewModel()
        let composeVM = emailListVM.composeViewModelForNewMessage()
        XCTAssertEqual(composeVM.state.from, expectedFrom)
    }

    func testComposePrefilledFromAccountIsDefaultAccountFromUnifiedIboxWithMultipleAccounts() {
        let expectedFrom = inbox.account.user
        secondAccountSetUp()
        AppSettings.shared.defaultAccount = account.user.address
        setupViewModel(forfolder: UnifiedInbox())
        let composeVM = emailListVM.composeViewModelForNewMessage()
        XCTAssertEqual(composeVM.state.from, expectedFrom)
    }

    func testComposePrefilledFromAccountIsFolderAccountFromSpecificFolderWithMultipleAccounts() {
        let expectedFrom = inbox.account.user
        secondAccountSetUp()
        setupViewModel(forfolder: inbox)
        let composeVM = emailListVM.composeViewModelForNewMessage()
        XCTAssertEqual(composeVM.state.from, expectedFrom)
    }
}

// MARK: - HELPER

extension EmailListViewModelTest {

    private func setUpViewModel(forFolder folder: DisplayableFolderProtocol,
                                masterViewController: TestMasterViewController) {
        self.emailListVM = EmailListViewModel(delegate: masterViewController,
                                              folderToShow: folder)
    }

    private func setupViewModel(forfolder internalFolder: DisplayableFolderProtocol? = nil) {
        let folderToUse: DisplayableFolderProtocol
        if internalFolder == nil {
            folderToUse = inbox
        } else {
            folderToUse = internalFolder!
        }
        createViewModelWithExpectations(forFolder: folderToUse, expectedUpdateView: true)
    }

    private func setNewUpdateViewExpectation() {
        let updateViewExpectation = expectation(description: "UpdateViewCalled")
        masterViewController.expectationUpdateViewCalled = updateViewExpectation
    }

    private func createViewModelWithExpectations(forFolder folder: DisplayableFolderProtocol,
                                                 expectedUpdateView: Bool) {
        let viewModelTestDelegate = TestMasterViewController()
        masterViewController = viewModelTestDelegate
        setUpViewModel(forFolder: folder, masterViewController: viewModelTestDelegate)
    }

    private func setUpViewModelExpectations(expectedUpdateView: Bool = false,
                                            expectationDidInsertDataAt: Bool = false,
                                            expectationDidUpdateDataAt: Bool = false,
                                            expectationDidDeleteDataAt: Bool = false ) {
        var expectationUpdateViewCalled: XCTestExpectation?
        if expectedUpdateView {
            expectationUpdateViewCalled = expectation(description: "UpdateViewCalled")
        }

        var excpectationDidInsertDataAtCalled: XCTestExpectation?
        if expectationDidInsertDataAt {
            excpectationDidInsertDataAtCalled =
                expectation(description: "excpectationDidInsertDataAtCalled")
        }

        var excpectationDidUpdateDataAtCalled: XCTestExpectation?
        if expectationDidUpdateDataAt {
            excpectationDidUpdateDataAtCalled =
                expectation(description: "excpectationDidUpdateDataAtCalled")
        }

        var excpectationDidDeleteDataAtCalled: XCTestExpectation?
        if expectationDidDeleteDataAt {
            excpectationDidDeleteDataAtCalled =
                expectation(description: "excpectationDidInsertDataAtCalled")
        }

        masterViewController =
            TestMasterViewController(expectationUpdateView: expectationUpdateViewCalled,
                                     expectationDidInsertDataAt: excpectationDidInsertDataAtCalled,
                                     expectationDidUpdateDataAt: excpectationDidUpdateDataAtCalled,
                                     expectationDidRemoveDataAt: excpectationDidDeleteDataAtCalled)
        emailListVM.delegate = masterViewController
    }

    private func getSafeLastLookAt() -> Date {
        guard let safeLastLookedAt = inbox?.lastLookedAt as Date? else {
            XCTFail()
            return Date()
        }
        return safeLastLookedAt
    }

    private func givenThereIsA(folderType: FolderType) {
        inbox = Folder(name: "-", parent: inbox, account: account, folderType: folderType)
        inbox.session.commit()
    }

    @discardableResult private func givenThereIsAMessageIn(folderType: FolderType) -> Message? {
        givenThereIsA(folderType: folderType)
        let msg = TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: inbox).first
        Session.main.commit()
        return msg
    }
}

private class TestMasterViewController: EmailListViewModelDelegate {
    var expectationUpdateViewCalled: XCTestExpectation?
    var excpectationDidInsertDataAtCalled: XCTestExpectation?
    var expectationDidUpdateDataAtCalled: XCTestExpectation?
    var expectationDidRemoveDataAtCalled: XCTestExpectation?

    init(expectationUpdateView: XCTestExpectation? = nil,
         expectationDidInsertDataAt: XCTestExpectation? = nil,
         expectationDidUpdateDataAt: XCTestExpectation? = nil,
         expectationDidRemoveDataAt: XCTestExpectation? = nil) {
        self.expectationUpdateViewCalled = expectationUpdateView
        self.excpectationDidInsertDataAtCalled = expectationDidInsertDataAt
        self.expectationDidUpdateDataAtCalled = expectationDidUpdateDataAt
        self.expectationDidRemoveDataAtCalled = expectationDidRemoveDataAt
    }

    func setToolbarItemsEnabledState(to newValue: Bool) {
        XCTFail()
    }

    func select(itemAt indexPath: IndexPath) {
        XCTFail()
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didInsertDataAt indexPaths: [IndexPath]) {
        if let excpectationDidInsertDataAtCalled = excpectationDidInsertDataAtCalled {
            excpectationDidInsertDataAtCalled.fulfill()
        } else {
            XCTFail()
        }
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didUpdateDataAt indexPaths: [IndexPath]) {
        if let expectationDidUpdateDataAtCalled = expectationDidUpdateDataAtCalled {
            expectationDidUpdateDataAtCalled.fulfill()
        } else {
            XCTFail()
        }
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didRemoveDataAt indexPaths: [IndexPath]) {
        if let expectationDidRemoveDataAtCalled = expectationDidRemoveDataAtCalled {
            expectationDidRemoveDataAtCalled.fulfill()
        } else {
            XCTFail()
        }
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didMoveData atIndexPath: IndexPath,
                            toIndexPath: IndexPath) {
        XCTFail()
    }

    func willReceiveUpdates(viewModel: EmailDisplayViewModel) {
        //not yet defined
    }

    func allUpdatesReceived(viewModel: EmailDisplayViewModel) {
        //not yet defined
    }

    func reloadData(viewModel: EmailDisplayViewModel) {
        //not yet defined
    }

    //not exist anymore
    func emailListViewModel(viewModel: EmailListViewModel,
                            didUpdateUndisplayedMessage message: Message) {
        XCTFail()
    }

    func showUnflagButton(enabled: Bool) {
        XCTFail()
    }

    func showUnreadButton(enabled: Bool) {
        XCTFail()
    }

    //not exist anymore
    func updateView() {
        if let expectationUpdateViewCalled = expectationUpdateViewCalled {
            expectationUpdateViewCalled.fulfill()
        } else {
            XCTFail()
        }
    }

    func showEmail(forCellAt: IndexPath) {
    }

    func showEditDraftInComposeView() {
    }

    func deselect(itemAt indexPath: IndexPath) {
    }
}
