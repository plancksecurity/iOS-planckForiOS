//
//  EmailListViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 22/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//


import XCTest
@testable import pEpForiOS
@testable import MessageModel

class EmailListViewModelTest: CoreDataDrivenTestBase {
    var folder: Folder!
    var trashFolder: Folder!
    var emailListVM : EmailListViewModel!
    var server: TestServer!
    var masterViewController: TestMasterViewController!

    /** this set up a view model with one account and one folder saved **/
    override func setUp() {
        super.setUp()

        let acc = cdAccount.account()

        folder = Folder(name: "inbox", parent: nil, account: acc, folderType: .inbox)
        folder.save()
        trashFolder = Folder(name: "trash", parent: nil, account: folder.account, folderType: .trash)
        trashFolder.save()

    }

    //mark: Test section

    func testViewModelSetUp() {
        setupViewModel()
    }

    func testCleanInitialSetup() {
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func test10MessagesInInitialSetup() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func test10MessagesThatEngineHasNotProcessedYet() {
        TestUtil.createMessages(number: 10, engineProccesed: false, inFolder: folder)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 0)
    }

    func testLastLookAtIsUpdated(){
        setupViewModel()

        emailListVM.updateLastLookAt()

        let lastLookAtBeforeUpdate: Date = getSafeLastLookAt()
        emailListVM.updateLastLookAt()
        let lastLookAtAfterUpdate: Date = getSafeLastLookAt()

        //Check dates are diferent and after is greater than before. 
        let comparison = lastLookAtBeforeUpdate.compare(lastLookAtAfterUpdate)
        XCTAssertEqual(comparison, ComparisonResult.orderedAscending)
    }

    func testGetFolderName() {
        setupViewModel()
        XCTAssertEqual(folder.localizedName, emailListVM.getFolderName())
    }

    func testGetDestructiveAction() {
        TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: folder)
        setupViewModel()
        let destructiveAction = emailListVM.getDestructiveActtion(forMessageAt: 0)

        XCTAssertEqual(destructiveAction, .trash)
    }

    func testGetDestructiveActionInOutgoingFolderIsTrash() {
        _ = givenThereIsAMessageIn(folderType: .outbox)
        setupViewModel()

        let destructiveAction = emailListVM.getDestructiveActtion(forMessageAt: 0)

        XCTAssertEqual(destructiveAction, .trash)
    }

    func testShouldShowToolbarEditButtonsIfItsNotOutboxFolder() {
        setupViewModel()

        var showToolbarButtons = emailListVM.shouldShowToolbarEditButtons()
        XCTAssertTrue(showToolbarButtons)

        givenThereIsA(folderType: .outbox)
        setupViewModel()

        showToolbarButtons = emailListVM.shouldShowToolbarEditButtons()
        XCTAssertFalse(showToolbarButtons)
    }

    func testUnreadFilterActive() {
        setupViewModel()

        var unreadActive = emailListVM.unreadFilterEnabled()

        XCTAssertFalse(unreadActive)

        setupViewModel()

        let filter = CompositeFilter<FilterBase>()
        filter.add(filter: UnreadFilter())
        emailListVM.addFilter(filter)
        setUpViewModelExpectations(expectedUpdateView: true)
        emailListVM.isFilterEnabled = true

        waitForExpectations(timeout: TestUtil.waitTime)
        unreadActive = emailListVM.unreadFilterEnabled()

        XCTAssertTrue(unreadActive)

    }

    func testGetFlagAndMoreAction() {
        let messages = TestUtil.createMessages(number: 1, engineProccesed: true, inFolder: folder)
        setupViewModel()

        var flagAction = emailListVM.getFlagAction(forMessageAt: 0)
        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)

        XCTAssertEqual(flagAction, .flag)
        XCTAssertEqual(moreAction, .more)

        messages[0].imapFlags?.flagged = true
        messages[0].save()

        flagAction = emailListVM.getFlagAction(forMessageAt: 0)

        XCTAssertEqual(flagAction, .unflag)

    }

    func testGetFlagAndMoreActionInOutgoingFolderIsNil() {
        _ = givenThereIsAMessageIn(folderType: .outbox)
        setupViewModel()

        let flagAction = emailListVM.getFlagAction(forMessageAt: 0)
        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)

        XCTAssertEqual(flagAction, nil)
        XCTAssertEqual(moreAction, nil)
    }

    func testGetFlagAndMoreActionInDraftFolderIsNil() {
        _ = givenThereIsAMessageIn(folderType: .drafts)
        setupViewModel()

        let flagAction = emailListVM.getFlagAction(forMessageAt: 0)
        let moreAction = emailListVM.getMoreAction(forMessageAt: 0)

        XCTAssertEqual(flagAction, nil)
        XCTAssertEqual(moreAction, nil)

    }

    func testIsDraftFolder() {
        setupViewModel()

        var isDraft = emailListVM.folderIsDraft()

        XCTAssertFalse(isDraft)

        givenThereIsA(folderType: .drafts)
        setupViewModel()

        isDraft = emailListVM.folderIsDraft()

        XCTAssertTrue(isDraft)
    }

    func testIsOutboxFolder() {
        setupViewModel()

        var isOutBox = emailListVM.folderIsOutbox()

        XCTAssertFalse(isOutBox)

        givenThereIsA(folderType: .outbox)
        setupViewModel()

        isOutBox = emailListVM.folderIsOutbox()

        XCTAssertTrue(isOutBox)


    }

    func testAccountExists() {
        setupViewModel()

        var noAccounts = emailListVM.noAccountsExist()

        XCTAssertFalse(noAccounts)

        cdAccount.delete()
        setupViewModel()

        noAccounts = emailListVM.noAccountsExist()

        XCTAssertTrue(noAccounts)
    }

    //mark: Search section

    func testSetSearchFilterWith0results() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        setSearchFilter(text: "blabla@blabla.com")
        XCTAssertEqual(emailListVM.rowCount, 0)
    }


    func testRemoveSearchFilterAfter0Results() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 10)
        setSearchFilter(text: "blabla@blabla.com")
        XCTAssertEqual(emailListVM.rowCount, 0)
        removeSearchFilter()
        XCTAssertEqual(emailListVM.rowCount, 10)
    }

    func testSetSearchFilterAddressWith3results() {
        let textToSearch = "searchTest@mail.com"
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        TestUtil.createMessage(inFolder: folder,
                      from: Identity.create(address: textToSearch),
                      tos: [folder.account.user]).save()
        TestUtil.createMessage(inFolder: folder,
                      from: Identity.create(address: textToSearch),
                      tos: [folder.account.user]).save()
        TestUtil.createMessage(inFolder: folder,
                      from: Identity.create(address: textToSearch),
                      tos: [folder.account.user]).save()
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 13)
        setSearchFilter(text: "searchTest")
        XCTAssertEqual(emailListVM.rowCount, 3)
    }

    func testSetSearchFilterShortMessageWith1results() {
        let textToSearch = "searchTest"
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        TestUtil.createMessage(inFolder: folder,
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
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        TestUtil.createMessage(inFolder: folder,
                      from: Identity.create(address: "mail@mail.com"),
                      shortMessage: textToSearch).save()
        TestUtil.createMessage(inFolder: folder,
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
        let msgs = TestUtil.createMessages(number: 10, inFolder: folder)
        setupViewModel()
        var index = emailListVM.index(of: msgs[0])
        XCTAssertEqual(index, 9)
        index = emailListVM.index(of: msgs[9])
        XCTAssertEqual(index, 0)
    }

    func testViewModel() {
        let msg = TestUtil.createMessage(inFolder: folder, from: folder.account.user)
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

    func testSetUpFilterViewModel() {
        var filterEnabled = false
        setupViewModel()
        XCTAssertEqual(filterEnabled, emailListVM.isFilterEnabled)
        filterEnabled = true
        setUpViewModelExpectations(expectedUpdateView: true)
        emailListVM.isFilterEnabled = filterEnabled
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(filterEnabled, emailListVM.isFilterEnabled)
    }

    func testNewMessageReceivedAndDisplayedInTheCorrectPosition() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 10)
        setUpMessageFolderDelegate()
        setUpViewModelExpectations(expectationDidInsertDataAt: true)
        let msg = TestUtil.createMessage(inFolder: folder, from: folder.account.user)
        msg.save()
        server.insertData(message: msg)
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertEqual(emailListVM.rowCount, 11)
        var index = emailListVM.index(of: msg)
        XCTAssertEqual(index, 0)
        let nonShownMsg = TestUtil.createMessage(inFolder: trashFolder, from: folder.account.user)
        nonShownMsg.save()
        server.insertData(message: nonShownMsg)
        XCTAssertEqual(emailListVM.rowCount, 11)
        index = emailListVM.index(of: msg)
        XCTAssertEqual(index, 0)
    }

    func testNewMessageUpdateReceivedAndDisplayed() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        let msg = TestUtil.createMessage(inFolder: folder, from: folder.account.user)
        msg.imapFlags?.flagged = false
        msg.save()
        XCTAssertFalse((msg.imapFlags?.flagged)!)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 11)
        setUpMessageFolderDelegate()
        setUpViewModelExpectations(expectationDidUpdateDataAt: true)
        msg.imapFlags?.flagged = true
        msg.save()
        server.updateData(message: msg)
        waitForExpectations(timeout: TestUtil.waitTime)
        var index = emailListVM.index(of: msg)
        if let ind = index {
            let newMsg = emailListVM.message(representedByRowAt: IndexPath(row: ind, section: 0))
            XCTAssertTrue((newMsg?.imapFlags?.flagged)!)
        } else {
            XCTFail()
        }

        let nonShownMsg = TestUtil.createMessage(inFolder: trashFolder, from: folder.account.user)
        nonShownMsg.save()
        server.insertData(message: nonShownMsg)
        XCTAssertEqual(emailListVM.rowCount, 11)
        index = emailListVM.index(of: nonShownMsg)
        XCTAssertNil(index)
    }

    func testNewMessageDeleteReceivedAndDisplayed() {
        TestUtil.createMessages(number: 10, engineProccesed: true, inFolder: folder)
        let msg = TestUtil.createMessage(inFolder: folder, from: folder.account.user)
        msg.imapFlags?.flagged = false
        msg.save()
        XCTAssertFalse((msg.imapFlags?.flagged)!)
        setupViewModel()
        XCTAssertEqual(emailListVM.rowCount, 11)
        setUpMessageFolderDelegate()
        setUpViewModelExpectations(expectationDidDeleteDataAt: true)
        msg.delete()
        server.deleteData(message: msg)
        waitForExpectations(timeout: TestUtil.waitTime)
        var index = emailListVM.index(of: msg)
        XCTAssertNil(index)
        XCTAssertEqual(emailListVM.rowCount, 10)

        let nonShownMsg = TestUtil.createMessage(inFolder: trashFolder, from: folder.account.user)
        nonShownMsg.save()
        server.insertData(message: nonShownMsg)
        nonShownMsg.delete()
        server.deleteData(message: msg)
        XCTAssertEqual(emailListVM.rowCount, 10)
        index = emailListVM.index(of: nonShownMsg)
        XCTAssertNil(index)
    }

    func testgetMoveToFolderViewModel() {
        let preMessages = TestUtil.createMessages(number: 4, inFolder: folder)
        let index: [IndexPath] = [IndexPath(row:0,section:1), IndexPath(row:0,section:2)]
        setupViewModel()

        let accountvm = emailListVM.getMoveToFolderViewModel(forSelectedMessages: index)

        let postMessages = accountvm!.items[0].messages
        XCTAssertEqual(index.count, postMessages.count)
    }

    func testFlagUnflagMessageIsImmediate() {
        givenThereIsAMessageIn(folderType: .inbox)
        setupViewModel()

        let indexPath = IndexPath(row: 0, section: 0)

        emailListVM.setFlagged(forIndexPath: indexPath)
        guard let isFlagged = emailListVM.viewModel(for: indexPath.row)?.isFlagged else {
            XCTFail()
            return
        }

        emailListVM.unsetFlagged(forIndexPath: indexPath)
        guard let isNotFlagged = emailListVM.viewModel(for: indexPath.row)?.isFlagged else {
            XCTFail()
            return
        }
        let expectationMain = expectation(description: "message is saved in main thread")
        DispatchQueue.main.async {
            expectationMain.fulfill()
        }

        let isImmediate = isFlagged != isNotFlagged
        XCTAssertTrue(isImmediate)
        wait(for: [expectationMain], timeout: TestUtil.waitTime)
    }

    // Mark: setting up

    fileprivate func setUpViewModel(masterViewController: TestMasterViewController) {
        let msgsyncservice = MessageSyncService()
        self.emailListVM = EmailListViewModel(emailListViewModelDelegate: masterViewController,
                                              messageSyncService: msgsyncservice,
                                              folderToShow: folder)

    }

    fileprivate func setUpMessageFolderDelegate() {
        self.server = TestServer(messageFolderDelegate: emailListVM)
    }

    fileprivate func setupViewModel() {
        createViewModelWithExpectations(expectedUpdateView: true)
    }

    fileprivate func setSearchFilter(text: String) {
        setNewUpdateViewExpectation()
        emailListVM.setSearchFilter(forSearchText: text)
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    fileprivate func removeSearchFilter() {
        setNewUpdateViewExpectation()
        emailListVM.removeSearchFilter()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    fileprivate func setNewUpdateViewExpectation() {
        let updateViewExpectation = expectation(description: "UpdateViewCalled")
        masterViewController.expectationUpdateViewCalled = updateViewExpectation
    }

    fileprivate func createViewModelWithExpectations(expectedUpdateView: Bool) {
        var viewModelTestDelegate : TestMasterViewController?

        if expectedUpdateView {
            let updateViewExpectation = expectation(description: "UpdateViewCalled")
            viewModelTestDelegate = TestMasterViewController(
                expectationUpdateView: updateViewExpectation)
        }
        guard let vmTestDelegate = viewModelTestDelegate else {
            XCTFail()
            return
        }
        self.masterViewController = viewModelTestDelegate
        setUpViewModel(masterViewController: vmTestDelegate)
        waitForExpectations(timeout: TestUtil.waitTime)
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
            excpectationDidInsertDataAtCalled = expectation(description: "excpectationDidInsertDataAtCalled")
        }

        var excpectationDidUpdateDataAtCalled: XCTestExpectation?
        if expectationDidUpdateDataAt {
            excpectationDidUpdateDataAtCalled = expectation(description: "excpectationDidUpdateDataAtCalled")
        }

        var excpectationDidDeleteDataAtCalled: XCTestExpectation?
        if expectationDidDeleteDataAt {
            excpectationDidDeleteDataAtCalled = expectation(description: "excpectationDidInsertDataAtCalled")
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

    @discardableResult private func givenThereIsAMessageIn(folderType: FolderType)-> Message? {
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

    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        if let excpectationDidInsertDataAtCalled = excpectationDidInsertDataAtCalled {
            excpectationDidInsertDataAtCalled.fulfill()
        } else {
            XCTFail()
        }
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPaths: [IndexPath]) {
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

    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
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
        } else {
            XCTFail()
        }
    }
}

//this is the server
class TestServer {
    var messageFolderDelegate : MessageFolderDelegate
    init(messageFolderDelegate: MessageFolderDelegate) {
        self.messageFolderDelegate = messageFolderDelegate
    }
    func insertData(message: Message) {
        self.messageFolderDelegate.didCreate(messageFolder: message)
    }

    func updateData(message: Message) {
        self.messageFolderDelegate.didUpdate(messageFolder: message)
    }

    func deleteData(message: Message) {
        self.messageFolderDelegate.didDelete(messageFolder: message, belongingToThread: Set())
    }
}

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
