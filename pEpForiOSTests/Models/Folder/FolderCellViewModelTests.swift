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
        let result = parentViewModel.isParentOf(fcvm: sonViewModel)
        XCTAssertTrue(result)
    }

    func testIsNotParentOf() {
        let notSonFolder = Folder(name: Input.folderName, parent: nil, account: account, folderType: .normal)
        notSonFolder.session.commit()
        let folderViewModel = FolderCellViewModel(folder: folder, level: 0)
        let notSonViewModel = FolderCellViewModel(folder: notSonFolder, level: 0)
        let result = folderViewModel.isParentOf(fcvm: notSonViewModel)
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

}
