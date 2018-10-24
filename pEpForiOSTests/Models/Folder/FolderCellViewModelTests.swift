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
    
    func testIsSelectable() {
        givenAViewModelWithFolderAndLevel()
        let isSelectable = viewModel.isSelectable
        let inputSelectable = folder.isLocalFolder || folder.selectable
        XCTAssertEqual(isSelectable, inputSelectable)
    }
    
    func givenAViewModelWithFolderAndLevel() {
        
        let level = Input.level
        viewModel = FolderCellViewModel(folder: folder, level: level)
    }
}
