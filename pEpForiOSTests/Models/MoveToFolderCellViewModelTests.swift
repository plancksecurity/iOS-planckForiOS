//
//  MoveToFolderCellViewModel.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 01/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel


class MoveToFolderCellViewModelTests: AccountDrivenTestBase {

    var viewmodel: MoveToFolderCellViewModel!

    func testIsValidFolder() {
        givenThereIsAValidFolder()
        XCTAssertTrue(viewmodel.isSelectable)
    }

    func testDrafstIsInvalidFolder() {
        givenThereIsADraftsFolder()
        XCTAssertFalse(viewmodel.isSelectable)
    }

    func testSentIsInvalidFoldeR() {
        givenThereIsASentFolder()
        XCTAssertFalse(viewmodel.isSelectable)
    }

    func givenThereIsAValidFolder() {
        let folder =
            Folder(name: "inbox",
                   parent: nil,
                   account: account,
                   folderType: .inbox,
                   selectable: true)
        folder.session.commit()
        viewmodel = MoveToFolderCellViewModel(folder: folder, level: 0)
    }
    
    func givenThereIsADraftsFolder() {
        let folder =
            Folder(name: "inbox",
                   parent: nil,
                   account: account,
                   folderType: .inbox,
                   selectable: true)
        folder.session.commit()
        let drafts =
            Folder(name: "drafts",
                   parent: folder,
                   account: account,
                   folderType: .drafts,
                   selectable: true)
        drafts.session.commit()
        viewmodel = MoveToFolderCellViewModel(folder: drafts, level: 1)
    }

    func givenThereIsASentFolder() {
        let folder =
            Folder(name: "inbox",
                   parent: nil,
                   account: account,
                   folderType: .inbox,
                   selectable: true)
        folder.session.commit()
        let sent =
            Folder(name: "sent",
                   parent: folder,
                   account: account,
                   folderType: .sent,
                   selectable: true)
        sent.session.commit()
        viewmodel = MoveToFolderCellViewModel(folder: sent, level: 1)
    }

 }
