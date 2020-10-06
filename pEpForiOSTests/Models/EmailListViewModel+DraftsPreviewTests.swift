//
//  EmailListViewModel+DraftsPreviewTests.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 05/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class EmailListViewModel_DraftsPreviewTests: XCTestCase {

    // sut - System Under Test
    private var sut: MockEmailListViewModel!

    private static var testMode: TestMode = .notSpecified

    private var selectDidHandle: TestBoolState = .notChanged
    private var deselectDidHandle: TestBoolState = .notChanged
    private var showEmailDidHandle: TestBoolState = .notChanged
    private var showEditDraftInComposeViewDidHandle: TestBoolState = .notChanged

    override func setUp() {
        sut = MockEmailListViewModel(delegate: self,
                                     folderToShow: UnifiedDraft())
        // Reset states for our mocked vm delegate for EmailListViewModelDelegate
        selectDidHandle = .notChanged
        deselectDidHandle = .notChanged
        showEmailDidHandle = .notChanged
        showEditDraftInComposeViewDidHandle = .notChanged
    }

    override func tearDown() {
        sut = nil
    }

    func testIsSelectableItemMockData() {
        // GIVEN
        EmailListViewModel_DraftsPreviewTests.testMode = .selectableAndEditableItem
        // WHEN
        let isSelectable = sut.isSelectable(messageAt: IndexPath(row: 0, section: 0))
        // THEN
        XCTAssertTrue(isSelectable)
    }

    func testIsNotSelectableItemMockData() {
        // GIVEN
        EmailListViewModel_DraftsPreviewTests.testMode = .notSelectableAndNotEditableItem
        // WHEN
        let isSelectable = sut.isSelectable(messageAt: IndexPath(row: 0, section: 0))
        // THEN
        XCTAssertFalse(isSelectable)
    }

    func testIsEditableItemMockData() {
        // GIVEN
        EmailListViewModel_DraftsPreviewTests.testMode = .notSelectableButEditableItem
        // WHEN
        let isEditable = sut.isEditable(messageAt: IndexPath(row: 0, section: 0))
        // THEN
        XCTAssertTrue(isEditable)
    }

    func testIsNotEditableItemMockData() {
        // GIVEN
        EmailListViewModel_DraftsPreviewTests.testMode = .notSelectableAndNotEditableItem
        // WHEN
        let isEditable = sut.isEditable(messageAt: IndexPath(row: 0, section: 0))
        // THEN
        XCTAssertFalse(isEditable)
    }

    func testHandleDidSelectRowWhenItemIsSelectableButNotEditable() {
        // GIVEN
        EmailListViewModel_DraftsPreviewTests.testMode = .selectableButNotEditableItem
        // WHEN
        sut.handleDidSelectRow(indexPath: IndexPath(row: 0, section: 0))
        // THEN
        XCTAssertTrue(selectDidHandle == .changed)
        XCTAssertTrue(showEmailDidHandle == .changed)
        XCTAssertTrue(deselectDidHandle == .notChanged)
        XCTAssertTrue(showEditDraftInComposeViewDidHandle == .notChanged)
    }
    func testSelectItemWhenIsNotSelectableAndNotEditable() {
        // GIVEN
        EmailListViewModel_DraftsPreviewTests.testMode = .notSelectableAndNotEditableItem
        // WHEN
        sut.handleDidSelectRow(indexPath: IndexPath(row: 0, section: 0))
        // THEN
        XCTAssertTrue(deselectDidHandle == .changed)
        XCTAssertTrue(selectDidHandle == .notChanged)
        XCTAssertTrue(showEmailDidHandle == .notChanged)
        XCTAssertTrue(showEditDraftInComposeViewDidHandle == .notChanged)
    }
}

extension EmailListViewModel_DraftsPreviewTests: EmailListViewModelDelegate {
    func select(itemAt indexPath: IndexPath) {
        selectDidHandle = .changed
    }

    func deselect(itemAt indexPath: IndexPath) {
        deselectDidHandle = .changed
    }

    func showEmail(forCellAt: IndexPath) {
        showEmailDidHandle = .changed
    }

    func showEditDraftInComposeView() {
        showEditDraftInComposeViewDidHandle = .changed
    }

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
    private struct Constants_Given {
        struct selectableButNotEditableItem {
            static let isSelectable = true
            static let isEditable = false
        }
        struct selectableAndEditableItem {
            static let isSelectable = true
            static let isEditable = true
        }
        struct notSelectableButEditableItem {
            static let isSelectable = false
            static let isEditable = true
        }
        struct notSelectableAndNotEditableItem {
            static let isSelectable = false
            static let isEditable = false
        }
    }

    private enum TestMode {
        case selectableButNotEditableItem
        case selectableAndEditableItem
        case notSelectableButEditableItem
        case notSelectableAndNotEditableItem
        case notSpecified
    }

    private enum TestBoolState {
        case notChanged
        case changed
    }

    class MockEmailListViewModel: EmailListViewModel {

        override func isSelectable(messageAt indexPath: IndexPath) -> Bool {
            var toReturn: Bool

            switch testMode {
            case .selectableButNotEditableItem,
                 .selectableAndEditableItem:
                toReturn = true
            case .notSelectableButEditableItem,
                 .notSelectableAndNotEditableItem:
                toReturn = false
            case .notSpecified:
                XCTFail("testMode is in illegal state!")
                return false
            }

            return toReturn
        }

        override func isEditable(messageAt indexPath: IndexPath) -> Bool {
            var toReturn: Bool

            switch testMode {
            case .selectableAndEditableItem,
                 .notSelectableButEditableItem:
                toReturn = true
            case .selectableButNotEditableItem,
                 .notSelectableAndNotEditableItem:
                toReturn = false
            case .notSpecified:
                XCTFail("testMode is in illegal state!")
                return false
            }

            return toReturn
        }
    }
}
