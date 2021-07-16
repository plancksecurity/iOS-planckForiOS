//
//  EmailListViewModel+DraftsPreviewTests.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 05/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class EmailListViewModel_DraftsPreviewTests: AccountDrivenTestBase {

    // sut - System Under Test
    private var sut: EmailListViewModel!
    private var folderToShow: Folder!

    private var didMarkAsFlagged: TestBoolState = .unspecified
    private var didMarkAsUnread: TestBoolState = .unspecified
    private var didMarkAsRead: TestBoolState = .unspecified
    private var didMarkAsUnflagged: TestBoolState = .unspecified
    private var selectDidHandle: TestBoolState = .unspecified
    private var deselectDidHandle: TestBoolState = .unspecified
    private var showEmailDidHandle: TestBoolState = .unspecified
    private var showEditDraftInComposeViewDidHandle: TestBoolState = .unspecified
    private var didFinishEditingMode: TestBoolState = .unspecified

    override func setUp() {
        selectDidHandle = .unspecified
        deselectDidHandle = .unspecified
        showEmailDidHandle = .unspecified
        showEditDraftInComposeViewDidHandle = .unspecified
        didFinishEditingMode = .unspecified
    }

    override func tearDown() {
        sut = nil
    }

    func testHandleDidSelectRowInStandardInboxMode() {
        let account = TestData().createWorkingAccount()
        let draftsFolder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        let _ = TestUtil.createMessage(uid: 1, inFolder: draftsFolder)
        sut = EmailListViewModel(delegate: self,
                                 folderToShow: draftsFolder)
        sut.startMonitoring()
        sut.handleDidSelectRow(indexPath: IndexPath(row: 0, section: 0))
        XCTAssertTrue(showEmailDidHandle == .called)
    }

    func testHandleDidSelectRowInDraftsPreviewMode() {
        let account = TestData().createWorkingAccount()
        let draftsFolder = Folder(name: "drafts", parent: nil, account: account, folderType: .drafts)
        let _ = TestUtil.createMessage(uid: 1, inFolder: draftsFolder)
        sut = EmailListViewModel(delegate: self,
                                 folderToShow: draftsFolder)
        sut.startMonitoring()
        sut.handleDidSelectRow(indexPath: IndexPath(row: 0, section: 0))
        XCTAssertTrue(showEditDraftInComposeViewDidHandle == .called)
    }
}

extension EmailListViewModel_DraftsPreviewTests: EmailListViewModelDelegate {

    func didMarkAsUnflagged(rows: [Int]) {
        didMarkAsUnflagged = .called
    }

    func didMarkAsRead(rows: [Int]) {
        didMarkAsRead = .called
    }

    func didMarkAsUnread(rows: [Int]) {
        didMarkAsUnread = .called
    }

    func didMarkAsFlagged(rows: [Int]) {
        didMarkAsFlagged = .called
    }

    func select(itemAt indexPath: IndexPath) {
        selectDidHandle = .called
    }

    func deselect(itemAt indexPath: IndexPath) {
        deselectDidHandle = .called
    }

    func showEmail(forCellAt: IndexPath) {
        showEmailDidHandle = .called
    }

    func showEditDraftInComposeView() {
        showEditDraftInComposeViewDidHandle = .called
    }

    func finishEditingMode() {
        didFinishEditingMode = .called
    }

    // These tests are for different features.
    func setToolbarItemsEnabledState(to newValue: Bool) {}
    func showUnflagButton(enabled: Bool) {}
    func showUnreadButton(enabled: Bool) {}
    func emailListViewModel(viewModel: EmailDisplayViewModel, didInsertDataAt indexPaths: [IndexPath]) {}
    func emailListViewModel(viewModel: EmailDisplayViewModel, didUpdateDataAt indexPaths: [IndexPath]) {}
    func emailListViewModel(viewModel: EmailDisplayViewModel, didRemoveDataAt indexPaths: [IndexPath]) {}
    func emailListViewModel(viewModel: EmailDisplayViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {}
    func willReceiveUpdates(viewModel: EmailDisplayViewModel) {}
    func allUpdatesReceived(viewModel: EmailDisplayViewModel) {}
    func reloadData(viewModel: EmailDisplayViewModel) {}
}

// MARK: - Mock Data

extension EmailListViewModel_DraftsPreviewTests {
    private enum TestBoolState {
        case unspecified
        case called
    }
}
