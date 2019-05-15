//
//  FolderCellViewModelTests.swift
//  pEpForiOSTests
//
//  Created by Miguel Berrocal Gómez on 24/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
import MessageModel

class FolderCellViewModelTests: CoreDataDrivenTestBase {
    var viewModel: FolderCellViewModel!
    
    var folder : Folder!
    
    struct Input {
        static let folderName = "Escafoides"
        static let level : Int = 1
    }
    
    override func setUp() {
        super.setUp()
        folder = Folder(name: Input.folderName, parent: nil, account: account, folderType: .inbox)
        folder.save()
    }
    
    func testTitle() {
        givenAViewModelWithFolderAndLevel()
        let title = viewModel.title
        XCTAssertEqual(title, Input.folderName)
    }
    
    func testLeftPadding() {
        givenAViewModelWithFolderAndLevel()
        let leftPadding = viewModel.leftPadding
        XCTAssertEqual(leftPadding, Input.level)
    }
    
    func testIcon() {
        givenAViewModelWithFolderAndLevel()
        let icon = viewModel.icon
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
        folder = Folder(name: Input.folderName, parent: nil, account: account, folderType:.outbox, selectable: false)
        viewModel = FolderCellViewModel(folder: folder, level: 0)
    }
    
    func givenAviewModelWithUnifiedFolder() {
        viewModel = FolderCellViewModel(folder: UnifiedInbox(), level: 0)
    }

    func givenAViewModelWithLocalFolder() {
        folder = Folder(name: Input.folderName, parent: nil, account: account, folderType: .outbox)
        viewModel = FolderCellViewModel(folder: folder, level: 0)

    }

    func givenAViewModelWithFolderAndLevel() {

        let level = Input.level
        viewModel = FolderCellViewModel(folder: folder, level: level)
    }
}
