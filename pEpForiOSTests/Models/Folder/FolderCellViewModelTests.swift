//
//  FolderCellViewModelTests.swift
//  pEpForiOSTests
//
//  Created by Miguel Berrocal Gómez on 24/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class FolderCellViewModelTests: AccountDrivenTestBase {
    var viewModel: FolderCellViewModel!
    
    var folder : Folder!
    
    struct Input {
        static let folderName = "Escafoides"
        static let level : Int = 1
    }
    
    override func setUp() {
        super.setUp()
        folder = Folder(name: Input.folderName, parent: nil, account: account, folderType: .inbox)
        folder.session.commit()
    }
    
    func testTitle() {
        givenAViewModelWithFolderAndLevel()
        let title = viewModel.title
        XCTAssertEqual(title, Input.folderName)
    }
    
    func testIcon() {
        givenAViewModelWithFolderAndLevel()
        let icon = viewModel.image
        let inputIcon = folder.folderType.getIcon()
        XCTAssertEqual(icon, inputIcon)
    }
    
    func testIsNotSelectable() {
        givenAViewModelWithFolderAndLevel()
        let isSelectable = viewModel.isSelectable
        XCTAssertFalse(isSelectable)
    }

    func testIsSelectableFolderIfIsUnified(){
        givenAviewModelWithUnifiedFolder()
        let isSelectable = viewModel.isSelectable
        XCTAssertTrue(isSelectable)
    }
    func testIsSelectableFolderIfIsLocal() {
        givenAViewModelWithLocalFolder()
        let isSelectable = viewModel.isSelectable
        XCTAssertTrue(isSelectable)
    }

    func testSelectableFolderIsSelectable() {
        givenAViewModelWithSelectableFolder()
        let isSelectable = viewModel.isSelectable
        XCTAssertTrue(isSelectable)
    }

    func givenAViewModelWithSelectableFolder() {
        folder = Folder(name: Input.folderName,
                        parent: nil,
                        account: account,
                        folderType:.outbox,
                        selectable: true)
        viewModel = FolderCellViewModel(folder: folder, level: 0)
    }
    
    func givenAviewModelWithUnifiedFolder() {
        viewModel = FolderCellViewModel(folder: UnifiedInbox(), level: 0)
    }

    func givenAViewModelWithLocalFolder() {
        folder = Folder(name: Input.folderName,
                        parent: nil,
                        account: account,
                        folderType: .outbox,
                        selectable: true)
        viewModel = FolderCellViewModel(folder: folder, level: 0)

    }

    func givenAViewModelWithFolderAndLevel() {

        let level = Input.level
        viewModel = FolderCellViewModel(folder: folder, level: level)
    }

    func testShouldHideSeparator() {
        folder = Folder(name: Input.folderName,
                        parent: nil,
                        account: account,
                        folderType: .outbox,
                        selectable: true)
        viewModel = FolderCellViewModel(folder: folder, level: 0)
        let result = viewModel.shouldHideSeparator()
        //outbox folder should hide the separator
        XCTAssert(result)
    }

    func testShouldNotHideSeparator() {
        folder = Folder(name: Input.folderName,
                        parent: nil,
                        account: account,
                        folderType: .normal,
                        selectable: true)
        viewModel = FolderCellViewModel(folder: folder, level: 0)
        let result = viewModel.shouldHideSeparator()
        //Normal folder should not hide the separator
        XCTAssertFalse(result)
    }

    func testIsSubfolder() {
        let sonFolder = Folder(name: Input.folderName, parent: folder, account: account, folderType: .normal)
        sonFolder.session.commit()
        viewModel = FolderCellViewModel(folder: sonFolder, level: 1)
        let result = viewModel.isSubfolder()
        XCTAssertTrue(result)
    }

    func testIsNotSubfolder() {
        let inbox = Folder(name: Input.folderName, parent: nil, account: account, folderType: .inbox)
        inbox.session.commit()
        viewModel = FolderCellViewModel(folder: inbox, level: 0)
        let result = viewModel.isSubfolder()
        XCTAssertFalse(result)
    }

    func testIsParentOf() {
        let sonFolder = Folder(name: Input.folderName, parent: folder, account: account, folderType: .normal)
        sonFolder.session.commit()
        let parentViewModel = FolderCellViewModel(folder: folder, level: 0)
        let sonViewModel = FolderCellViewModel(folder: sonFolder, level: 1)
        let result = parentViewModel.isAncestorOf(fcvm: sonViewModel)
        XCTAssertTrue(result)
    }

    func testIsNotParentOf() {
        let notSonFolder = Folder(name: Input.folderName, parent: nil, account: account, folderType: .normal)
        notSonFolder.session.commit()
        let folderViewModel = FolderCellViewModel(folder: folder, level: 0)
        let notSonViewModel = FolderCellViewModel(folder: notSonFolder, level: 0)
        let result = folderViewModel.isAncestorOf(fcvm: notSonViewModel)
        XCTAssertFalse(result)
    }

    func testHasSubfolders() {
        let sonFolder = Folder(name: Input.folderName, parent: folder, account: account, folderType: .normal)
        sonFolder.session.commit()
        let parentViewModel = FolderCellViewModel(folder: folder, level: 0)
        let result = parentViewModel.hasSubfolders()
        XCTAssertTrue(result)
    }

    func testHasNotSubfolders() {
        let fcvm = FolderCellViewModel(folder: folder, level: 0)
        let result = fcvm.hasSubfolders()
        XCTAssertFalse(result)
    }

    func testSetFolderCollapsedStateExpectation() {
        let exp = expectation(description: "setFolderCollapsedStateExpectation")
        let appSettingsMock = MockAppSettings(setFolderCollapsedStateExpectation:exp)
        folder = Folder(name: Input.folderName, parent: nil, account: account, folderType: .inbox)
        folder.session.commit()
        let parentViewModel = FolderCellViewModel(folder: folder, level: 0, appSettings: appSettingsMock)
        parentViewModel.handleFolderCollapsedStateChange()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

class MockAppSettings: AppSettingsProtocol {

    var removeCollapsedStateOfAccountWithAddressExpectation: XCTestExpectation?
    // getters
    var collapsedStateForAccountWithAddressExpectation: XCTestExpectation?
    var collapsedStateForFolderOfAccountExpectation: XCTestExpectation?
    // setters
    var setFolderCollapsedStateExpectation: XCTestExpectation?
    var setAccountCollapsedStateExpectation: XCTestExpectation?

    init(removeCollapsedStateOfAccountWithAddressExpectation: XCTestExpectation? = nil,
         collapsedStateForAccountWithAddressExpectation: XCTestExpectation? = nil,
         collapsedStateForFolderOfAccountExpectation: XCTestExpectation? = nil,
         setFolderCollapsedStateExpectation: XCTestExpectation? = nil,
         setAccountCollapsedStateExpectation: XCTestExpectation? = nil) {
        self.removeCollapsedStateOfAccountWithAddressExpectation = removeCollapsedStateOfAccountWithAddressExpectation
        self.collapsedStateForAccountWithAddressExpectation = collapsedStateForAccountWithAddressExpectation
        self.collapsedStateForFolderOfAccountExpectation = collapsedStateForFolderOfAccountExpectation
        self.setFolderCollapsedStateExpectation = setFolderCollapsedStateExpectation
        self.setAccountCollapsedStateExpectation = setAccountCollapsedStateExpectation
    }

    var keySyncEnabled: Bool = true

    var usePEPFolderEnabled: Bool = true

    var extraKeysEditable: Bool = true

    var unencryptedSubjectEnabled: Bool = true

    var threadedViewEnabled: Bool = true

    var passiveMode: Bool = true

    var defaultAccount: String? = "some@account.com"

    var lastKnownDeviceGroupState: DeviceGroupState = .grouped

    var shouldShowTutorialWizard: Bool = false

    var userHasBeenAskedForContactAccessPermissions: Bool = false

    var unsecureReplyWarningEnabled: Bool = false

    var verboseLogginEnabled: Bool = false

    // MARK: - Collapsing State

    func removeCollapsedStateOfAccountWithAddress(address: String) {
        fulfillIfNotNil(expectation: removeCollapsedStateOfAccountWithAddressExpectation)
    }

    func collapsedState(forAccountWithAddress address: String) -> Bool {
        fulfillIfNotNil(expectation: collapsedStateForAccountWithAddressExpectation)
        return true
    }

    func collapsedState(forFolderNamed folderName: String, ofAccountWithAddress address: String) -> Bool {
        fulfillIfNotNil(expectation: collapsedStateForFolderOfAccountExpectation)
        return true
    }

    func setFolderCollapsedState(address: String, folderName: String, isCollapsed: Bool) {
        fulfillIfNotNil(expectation: setFolderCollapsedStateExpectation)
    }

    func setAccountCollapsedState(address: String, isCollapsed: Bool) {
        fulfillIfNotNil(expectation: setAccountCollapsedStateExpectation)
    }

    private func fulfillIfNotNil(expectation: XCTestExpectation?) {
        if expectation != nil {
            expectation?.fulfill()
        }
    }
}
