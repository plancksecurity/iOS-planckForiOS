//!!!: is WIP (IOS-1495), ignore failing tests for now.

//
//  EmailListViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 22/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class EmailListViewModelTest: CoreDataDrivenTestBase {
    var folder: Folder!
    var trashFolder: Folder!
    var outboxFolder: Folder!
    var draftsFolder: Folder!
    var emailListVM : EmailListViewModel!
    var masterViewController: TestMasterViewController!

    /** this set up a view model with one account and one folder saved **/
    override func setUp() {
        super.setUp()

        let acc = cdAccount.account()

        folder = Folder(name: "inbox", parent: nil, account: acc, folderType: .inbox)
        trashFolder = Folder(name: "trash",
                             parent: nil,
                             account: folder.account,
                             folderType: .trash)
        outboxFolder = Folder(name: "outbox", parent: nil, account: acc, folderType: .outbox)
        draftsFolder = Folder(name: "drafts", parent: nil, account: acc, folderType: .drafts)
        moc.saveAndLogErrors()
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
         TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder, setUids: true)
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func testGetFolderName() {
        setupViewModel()
        XCTAssertEqual(Folder.localizedName(realName: self.folder.realName), emailListVM.folderName)
    }

    func testGetDestructiveAction() {
        TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: folder)
        setupViewModel()
        emailListVM.startMonitoring()
        let destructiveAction = emailListVM.getDestructiveActtion(forMessageAt: 0)

        XCTAssertEqual(destructiveAction, .trash)
    }

    func testGetDestructiveActionInOutgoingFolderIsTrash() {
        _ = givenThereIsAMessageIn(folderType: .outbox)
        setupViewModel()
        emailListVM.startMonitoring()
        let destructiveAction = emailListVM.getDestructiveActtion(forMessageAt: 0)

        XCTAssertEqual(destructiveAction, .trash)
    }

    func testShouldShowToolbarEditButtonsIfItsNotOutboxFolder() {
        setupViewModel()
        emailListVM.startMonitoring()
        var showToolbarButtons = emailListVM.shouldShowToolbarEditButtons()
        XCTAssertTrue(showToolbarButtons)

        givenThereIsA(folderType: .outbox)
        setupViewModel()
        emailListVM.startMonitoring()
        showToolbarButtons = emailListVM.shouldShowToolbarEditButtons()
        XCTAssertFalse(showToolbarButtons)
    }

    func testDefaultFilterActiveIsUnread() {
        let messages = TestUtil.createMessages(number: 20, engineProccesed: true, inFolder: folder)
        messages.forEach { (msg) in
            msg.imapFlags.seen = true
        }
        messages[0].imapFlags.seen = false
        messages[2].imapFlags.seen = false
        messages[4].imapFlags.seen = false
        messages[6].imapFlags.seen = false
        messages[8].imapFlags.seen = false

        setupViewModel()
        emailListVM.startMonitoring()

        var unreadActive = emailListVM.unreadFilterEnabled()
        XCTAssertFalse(unreadActive)

        XCTAssertEqual(20, emailListVM.rowCount)
        emailListVM.isFilterEnabled = true
        XCTAssertEqual(5, emailListVM.rowCount)
        setUpViewModelExpectations(expectationDidDeleteDataAt: true)
        let imap = ImapFlags()
        imap.seen = true
        messages[0].imapFlags = imap
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(4, emailListVM.rowCount)
        unreadActive = emailListVM.unreadFilterEnabled()
        XCTAssertTrue(unreadActive)
        emailListVM.isFilterEnabled = false
        XCTAssertEqual(20, emailListVM.rowCount)
    }

    func testGetFlagAndMoreAction() {
        let messages = TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: folder)
        setupViewModel()
        emailListVM.startMonitoring()
        var flagAction = emailListVM.getFlagAction(forMessageAt: 0)
        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)

        XCTAssertEqual(flagAction, .flag)
        XCTAssertEqual(moreAction, .more)

        messages[0].imapFlags.flagged = true
        messages[0].save()

        flagAction = emailListVM.getFlagAction(forMessageAt: 0)

        XCTAssertEqual(flagAction, .unflag)
    }

    func testGetFlagAndMoreActionInOutgoingFolderIsNil() {
        givenThereIsAMessageIn(folderType: .outbox)
        setupViewModel()
        emailListVM.startMonitoring()

        let flagAction = emailListVM.getFlagAction(forMessageAt: 0)
        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)

        XCTAssertEqual(flagAction, nil)
        XCTAssertEqual(moreAction, nil)
    }

    func testGetFlagAndMoreActionInDraftFolderIsNil() {
        givenThereIsAMessageIn(folderType: .drafts)
        setupViewModel()
        emailListVM.startMonitoring()
        let flagAction = emailListVM.getFlagAction(forMessageAt: 0)
        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)

        XCTAssertEqual(flagAction, nil)
        XCTAssertEqual(moreAction, nil)
    }

    func testAccountExists() {
        setupViewModel()
        emailListVM.startMonitoring()
        var noAccounts = emailListVM.showLoginView

        XCTAssertFalse(noAccounts)

        cdAccount.delete()
        setupViewModel()
        noAccounts = emailListVM.showLoginView

        XCTAssertTrue(noAccounts)
    }

    // MARK: - Search section

    func testSetSearchFilterWith0results() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        emailListVM.startMonitoring()
        emailListVM.setSearch(forSearchText: "blabla@blabla.com")
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func testRemoveSearchFilterAfter0Results() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 10)
        emailListVM.setSearch(forSearchText: "blabla@blabla.com")
        XCTAssertEqual(emailListVM.rowCount, 0)
        emailListVM.removeSearch()
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func testSetSearchFilterAddressWith3results() {
        let textToSearch = "searchTest@mail.com"
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        TestUtil.createMessage(inFolder: folder,
                      from: Identity(address: textToSearch),
                      tos: [folder.account.user],
                      uid: 666).save()
        TestUtil.createMessage(inFolder: folder,
                      from: Identity(address: textToSearch),
                      tos: [folder.account.user],
                      uid: 667).save()
        TestUtil.createMessage(inFolder: folder,
                      from: Identity(address: textToSearch),
                      tos: [folder.account.user],
                      uid: 668).save()
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 13)
        emailListVM.setSearch(forSearchText: textToSearch)
        XCTAssertEqual(emailListVM.rowCount, 3)
    }

    func testSetSearchFilterShortMessageWith1results() {
        let textToSearch = "searchTest"
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        TestUtil.createMessage(inFolder: folder,
                      from: Identity(address: "mail@mail.com"),
                      tos: [folder.account.user],
                      shortMessage: textToSearch,
                      uid: 666).save()
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 11)
        emailListVM.setSearch(forSearchText: textToSearch)
        XCTAssertEqual(emailListVM.rowCount, 1)
    }

    func testSetSearchMultipleSitesMatchInMessagesWith2results() {
        let textToSearch = "searchTest"
        let longText = "bla " + textToSearch + " bla"
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        TestUtil.createMessage(inFolder: folder,
                      from: Identity(address: "mail@mail.com"),
                      shortMessage: textToSearch,
                      uid: 666).save()
        TestUtil.createMessage(inFolder: folder,
                      from: Identity(address: "mail@mail.com"),
                      tos: [folder.account.user],
                      longMessage: longText,
                      uid: 667).save()
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 12)
        emailListVM.setSearch(forSearchText: textToSearch)
        XCTAssertEqual(emailListVM.rowCount, 2)
    }

    // Threading feature is currently non-existing. Keep this code, might help later.
//    //thread view nos is totaly disabled that means always false
//    func testCheckIfSettingsChanged() {
//        setupViewModel()
//        emailListVM.startMonitoring()
//        XCTAssertFalse(AppSettings.threadedViewEnabled)
//        AppSettings.threadedViewEnabled = true
//        XCTAssertFalse(emailListVM.checkIfSettingsChanged())
//    }

    // MARK: - cell for row
/*
    func testIndexFromMessage() {
        let msgs = TestUtil.createMessages(number: 10, inFolder: folder)
        setupViewModel()
        emailListVM.startMonitoring()
        var index = emailListVM.index(of: msgs[0])
        XCTAssertEqual(index, 9)
        index = emailListVM.index(of: msgs[9])
        XCTAssertEqual(index, 0)
    }*/

    func testViewModel() {
        let msg = TestUtil.createMessage(inFolder: folder, from: folder.account.user, uid: 1)
        msg.save()
        setupViewModel()
        emailListVM.startMonitoring()
        let index = emailListVM.index(of: msg)
        guard let ind = index else {
            XCTFail()
            return
        }
        let vm = emailListVM.viewModel(for: ind)
        XCTAssertEqual(vm?.message(), msg)
        XCTAssertEqual(vm?.subject, msg.shortMessage)
    }

//    func testSetUpFilterViewModel() {
//        var filterEnabled = false
//        setupViewModel()
//        XCTAssertEqual(filterEnabled, emailListVM.isFilterEnabled)
//        filterEnabled = true
//        setUpViewModelExpectations(expectedUpdateView: true)
//        emailListVM.isFilterEnabled = filterEnabled
//        waitForExpectations(timeout: TestUtil.waitTime)
//        XCTAssertEqual(filterEnabled, emailListVM.isFilterEnabled)
//    }

    func testNewMessageReceivedAndDisplayedInTheCorrectPosition() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 10)
        setUpViewModelExpectations(expectationDidInsertDataAt: true)
        let msg = TestUtil.createMessage(inFolder: folder, from: folder.account.user)
        msg.save()
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(emailListVM.rowCount, 11)
        var index = emailListVM.index(of: msg)
        XCTAssertEqual(index, 0)
        let nonShownMsg = TestUtil.createMessage(inFolder: trashFolder, from: folder.account.user)
        nonShownMsg.save()
        XCTAssertEqual(emailListVM.rowCount, 11)
        index = emailListVM.index(of: msg)
        XCTAssertEqual(index, 0)
    }

    func testNewMessageUpdateReceivedAndDisplayed() {
        let numMails = 10
        TestUtil.createMessages(number: numMails, engineProccesed: true, inFolder: folder)
        let msg = TestUtil.createMessage(inFolder: folder,
                                         from: folder.account.user,
                                         uid: numMails + 1)
        msg.imapFlags.flagged = false
        msg.save()
        XCTAssertFalse((msg.imapFlags.flagged))
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 11)
        msg.imapFlags.flagged = true
        msg.save()
        waitForExpectations(timeout: TestUtil.waitTime)
        var index = emailListVM.index(of: msg)
        if let ind = index {
            let newMsg = emailListVM.message(representedByRowAt: IndexPath(row: ind, section: 0))
            XCTAssertTrue((newMsg?.imapFlags.flagged)!)
        } else {
            XCTFail()
        }

        let nonShownMsg = TestUtil.createMessage(inFolder: trashFolder, from: folder.account.user)
        nonShownMsg.save()
        XCTAssertEqual(emailListVM.rowCount, 11)
        index = emailListVM.index(of: nonShownMsg)
        XCTAssertNil(index)
    }

    func testNewMessageDeleteReceivedAndDisplayed() {
        let numMails = 10
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        let msg = TestUtil.createMessage(inFolder: folder,
                                         from: folder.account.user,
                                         uid: numMails + 1)
        msg.imapFlags.flagged = false
        msg.save()
        XCTAssertFalse((msg.imapFlags.flagged))
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(emailListVM.rowCount, 11)
        setUpViewModelExpectations(expectationDidDeleteDataAt: true)
        msg.delete()
        waitForExpectations(timeout: TestUtil.waitTime)
        var index = emailListVM.index(of: msg)
        XCTAssertNil(index)
        XCTAssertEqual(emailListVM.rowCount, 10)

        let nonShownMsg = TestUtil.createMessage(inFolder: trashFolder, from: folder.account.user)
        nonShownMsg.save()
        nonShownMsg.delete()
        XCTAssertEqual(emailListVM.rowCount, 10)
        index = emailListVM.index(of: nonShownMsg)
        XCTAssertNil(index)
    }

    func testgetMoveToFolderViewModel() {
        TestUtil.createMessages(number: 4, inFolder: folder)
        let index: [IndexPath] = [IndexPath(row: 0, section: 1),
                                  IndexPath(row: 0, section: 2)]
        setupViewModel()
        emailListVM.startMonitoring()

        let accountvm = emailListVM.getMoveToFolderViewModel(forSelectedMessages: index)

        let postMessages = accountvm!.items[0].messages
        XCTAssertEqual(index.count, postMessages.count)
    }

    func testFlagUnflagMessageIsImmediate() {
        let message = givenThereIsAMessageIn(folderType: .inbox)
        let messageMoc = message?.cdMessage()?.managedObjectContext
        setupViewModel()
        emailListVM.startMonitoring()

        let indexPath = IndexPath(row: 0, section: 0)

        emailListVM.setFlagged(forIndexPath: [indexPath])
        guard let isFlagged = emailListVM.viewModel(for: indexPath.row)?.isFlagged else {
            XCTFail()
            return
        }

        emailListVM.unsetFlagged(forIndexPath: [indexPath])
        guard let isNotFlagged = emailListVM.viewModel(for: indexPath.row)?.isFlagged else {
            XCTFail()
            return
        }
        let messageDidSaveExpectation = expectation(description: "message is saved")
        messageDidSaveExpectation.expectedFulfillmentCount = 8

        NotificationCenter.default
            .addObserver(forName: Notification.Name.NSManagedObjectContextDidSave,
                         object: messageMoc,
                         queue: nil) { (notification) in
                            print("fulfill")
                            messageDidSaveExpectation.fulfill()
        }

        let isImmediate = isFlagged != isNotFlagged
        XCTAssertTrue(isImmediate)
        wait(for: [messageDidSaveExpectation], timeout: UnitTestUtils.waitTime)
    }

    func testMessageInOutboxAreNonEditableAndNonSelectable() {
        TestUtil.createMessage(uid: 1, inFolder: outboxFolder)
        moc.saveAndLogErrors()
        setupViewModel(forfolder: outboxFolder)
        emailListVM.startMonitoring()
        XCTAssertEqual(1, emailListVM.rowCount)
        let notEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(notEditable)
        let notSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(notSelectable)
    }

    func testMessageInInboxAreOnlySelectable() {
        TestUtil.createMessage(uid: 1, inFolder: folder)
        moc.saveAndLogErrors()
        setupViewModel()
        emailListVM.startMonitoring()
        XCTAssertEqual(1, emailListVM.rowCount)
        let isEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(isEditable)
        let isSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(isSelectable)
    }

    func testMessageInDraftsAreEditableAndSelectable() {
        TestUtil.createMessage(uid: 1, inFolder: draftsFolder)
        moc.saveAndLogErrors()
        setupViewModel(forfolder: draftsFolder)
        emailListVM.startMonitoring()
        XCTAssertEqual(1, emailListVM.rowCount)
        let isEditable = emailListVM.isEditable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(isEditable)
        let isSelectable = emailListVM.isSelectable(messageAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(isSelectable)
    }

    // Mark: - setting up

    fileprivate func setUpViewModel(forFolder folder: Folder, masterViewController: TestMasterViewController) {
        self.emailListVM = EmailListViewModel(emailListViewModelDelegate: masterViewController, folderToShow: folder)
    }

    fileprivate func setupViewModel(forfolder internalFolder: Folder? = nil) {
        let folderToUse: Folder
        if internalFolder == nil {
            folderToUse = folder
        } else {
            folderToUse = internalFolder!
        }
        createViewModelWithExpectations(forFolder: folderToUse, expectedUpdateView: true)
    }

    /*fileprivate func setSearchFilter(text: String) {
        setNewUpdateViewExpectation()
        emailListVM.setSearchFilter(forSearchText: text)
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    fileprivate func removeSearchFilter() {
        setNewUpdateViewExpectation()
        emailListVM.removeSearchFilter()
        waitForExpectations(timeout: TestUtil.waitTime)
    }*/

    fileprivate func setNewUpdateViewExpectation() {
        let updateViewExpectation = expectation(description: "UpdateViewCalled")
        masterViewController.expectationUpdateViewCalled = updateViewExpectation
    }

    fileprivate func createViewModelWithExpectations(forFolder folder: Folder, expectedUpdateView: Bool) {
        let viewModelTestDelegate = TestMasterViewController()
        setUpViewModel(forFolder: folder, masterViewController: viewModelTestDelegate)
    }

    fileprivate func setUpViewModelExpectations(expectedUpdateView: Bool = false,
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

        emailListVM.emailListViewModelDelegate = TestMasterViewController(
            expectationUpdateView: expectationUpdateViewCalled,
            expectationDidInsertDataAt: excpectationDidInsertDataAtCalled,
            expectationDidUpdateDataAt: excpectationDidUpdateDataAtCalled,
            expectationDidRemoveDataAt: excpectationDidDeleteDataAtCalled)
    }

    fileprivate func getSafeLastLookAt() -> Date {
        guard let safeLastLookedAt = folder?.lastLookedAt as Date? else {
            XCTFail()
            return Date()
        }
        return safeLastLookedAt
    }

    private func givenThereIsA(folderType: FolderType) {
        folder = Folder(name: "-", parent: folder, account: account, folderType: folderType)
        folder.save()
    }

    @discardableResult private func givenThereIsAMessageIn(folderType: FolderType) -> Message? {
        givenThereIsA(folderType: folderType)
        return TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: folder).first
    }
}

class TestMasterViewController: EmailListViewModelDelegate {

    var expectationUpdateViewCalled: XCTestExpectation?
    var excpectationDidInsertDataAtCalled: XCTestExpectation?
    var expectationDidUpdateDataAtCalled: XCTestExpectation?
    var expectationDidRemoveDataAtCalled: XCTestExpectation?
    var expetationDidChangeSeenStateForDataAt: XCTestExpectation?

    init(expectationUpdateView: XCTestExpectation? = nil,
         expectationDidInsertDataAt: XCTestExpectation? = nil,
         expectationDidUpdateDataAt: XCTestExpectation? = nil,
         expectationDidRemoveDataAt: XCTestExpectation? = nil) {
        self.expectationUpdateViewCalled = expectationUpdateView
        self.excpectationDidInsertDataAtCalled = expectationDidInsertDataAt
        self.expectationDidUpdateDataAtCalled = expectationDidUpdateDataAt
        self.expectationDidRemoveDataAtCalled = expectationDidRemoveDataAt
    }

    func willReceiveUpdates(viewModel: EmailListViewModel) {
        //not yet defined
        XCTFail()
    }

    func allUpdatesReceived(viewModel: EmailListViewModel) {
        //not yet defined
        XCTFail()
    }

    func reloadData(viewModel: EmailListViewModel) {
        //not yet defined
        XCTFail()
    }


    func emailListViewModel(viewModel: EmailListViewModel,
                            didInsertDataAt indexPaths: [IndexPath]) {
        if let excpectationDidInsertDataAtCalled = excpectationDidInsertDataAtCalled {
            excpectationDidInsertDataAtCalled.fulfill()
        } else {
            XCTFail()
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel,
                            didUpdateDataAt indexPaths: [IndexPath]) {
        if let expectationDidUpdateDataAtCalled = expectationDidUpdateDataAtCalled {
            expectationDidUpdateDataAtCalled.fulfill()
        } else {
            XCTFail()
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel,
                            didChangeSeenStateForDataAt indexPaths: [IndexPath]) {
        XCTFail("Currently unused in tests. Should not be called")
    }

    func emailListViewModel(viewModel: EmailListViewModel,
                            didRemoveDataAt indexPaths: [IndexPath]) {
        if let expectationDidRemoveDataAtCalled = expectationDidRemoveDataAtCalled {
            expectationDidRemoveDataAtCalled.fulfill()
        } else {
            XCTFail()
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel,
                            didMoveData atIndexPath: IndexPath,
                            toIndexPath: IndexPath) {
        XCTFail()
    }
//not exist anymore
    func emailListViewModel(viewModel: EmailListViewModel,
                            didUpdateUndisplayedMessage message: Message) {
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

    func checkIfSplitNeedsUpdate(indexpath: [IndexPath]) {
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
}

//class TestServer: MessageQueryResults {
//    var results: [Message] = [Message]()
//
//    required init(withFolder folder: Folder) {
//        super.init(withDisplayableFolder: folder)
//    }
//
//
//    override var count: Int {
//        return results.count
//    }
//
//    override subscript(index: Int) -> Message {
//        return results[index]
//    }
//
//    override func startMonitoring() throws {
//
//    }
//
//    func insertData(message: Message) {
//        results.append(message)
//        let ip = IndexPath(row: results.firstIndex(of: message)!, section: 0)
//        delegate?.didInsert(indexPath: ip)
//    }
//
//    func updateData(message: Message) {
//        let ip = IndexPath(row: results.firstIndex(of: message)!, section: 0)
//        delegate?.didUpdate(indexPath: ip)
//    }
//
//    func deleteData(message: Message) {
//        let index = results.firstIndex(of: message)
//        results.remove(at: index!)
//        let ip = IndexPath(row: index!, section: 0)
//        delegate?.didDelete(indexPath: ip)
//    }
//
//    func insertMessagesWithoutDelegate(messages: [Message]) {
//        results.append(contentsOf: messages)
//    }
//}

class TestDetailsViewController {
    var emailDisplayDelegate : EmailDisplayDelegate
    init(emailDisplayDelegate: EmailDisplayDelegate) {
        self.emailDisplayDelegate = emailDisplayDelegate
    }

    func emailDisplayDidChangeMarkSeen(message: Message) {
        self.emailDisplayDelegate.emailDisplayDidChangeMarkSeen(message: message)
    }

    func emailDisplayDidDelete(message: Message) {
        self.emailDisplayDelegate.emailDisplayDidDelete(message: message)
    }

    func emailDisplayDidFlag(message: Message) {
        self.emailDisplayDelegate.emailDisplayDidFlag(message: message)
    }

    func emailDisplayDidUnflag(message: Message) {
        self.emailDisplayDelegate.emailDisplayDidUnflag(message: message)
    }
}
