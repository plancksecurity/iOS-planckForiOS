//
//  FolderSectionViewModelTests.swift
//  pEpForiOSTests
//
//  Created by Miguel Berrocal Gómez on 23/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class FolderSectionViewModelTests: AccountDrivenTestBase {
    
    var viewModel: FolderSectionViewModel!
    var folder: Folder!
    
    override func setUp() {
        super.setUp()
        self.folder = Folder(name: "Escafoides", parent: nil, account: account, folderType: .inbox)
        self.folder.session.commit()
    }
    
    func testHiddenWhenUnifiedInbox() {
        givenThereIsAViewModelWithAccount(withUnifiedInbox: true)
        XCTAssertTrue(viewModel.sectionHeaderHidden)
    }
    
    func testNotHiddenWithoutUnifiedInbox() {
        givenThereIsAViewModelWithAccount(withUnifiedInbox: false)
        XCTAssertFalse(viewModel.sectionHeaderHidden)
    }
    
    func testUserNameWithAccount() {
        let account = TestData().createWorkingAccount()
        givenThereIsAViewModel(withUnifiedInbox: true, and: account)
        let userName = viewModel.userName
        guard let accountUserName = account.user.userName else {
            XCTFail("No user name in account")
            return
        }
        XCTAssertEqual(userName, accountUserName)
    }
    
    func testUserAddressWithAccount() {
        let account = TestData().createWorkingAccount()
        givenThereIsAViewModel(withUnifiedInbox: true, and: account)
        let userAddress = viewModel.userAddress
        let accountUserAddress = account.user.address
        XCTAssertEqual(userAddress, accountUserAddress)
    }

    func testUserNameIsEmptyWithoutAccount() {
        givenThereIsAViewModelWithoutAccount(withUnifiedInbox: true)
        let userName = viewModel.userName
        XCTAssertEqual(userName, "")
    }
    
    func testUserAddressIsEmptyWithoutAccount() {
        givenThereIsAViewModelWithoutAccount(withUnifiedInbox: true)
        let userAddress = viewModel.userAddress
        XCTAssertEqual(userAddress, "")
    }
    
    func testTypeIsEmail() {
        givenThereIsAViewModelWithoutAccount(withUnifiedInbox: true)
        let type = viewModel.type
        XCTAssertEqual(type, "Email")
    }
    
    func testSubscript() {
        givenThereIsAViewModelWithAccount(withUnifiedInbox: false)
        //let firstFolderName =
        //let myFolderName = folder.name
        //XCTAssertEqual(firstFolderName, myFolderName)
    }
    
    func givenThereIsAViewModelWithAccount(withUnifiedInbox: Bool) {
        givenThereIsAViewModel(withUnifiedInbox: withUnifiedInbox, and: account)
    }
    
    func givenThereIsAViewModelWithoutAccount(withUnifiedInbox: Bool) {
        givenThereIsAViewModel(withUnifiedInbox: withUnifiedInbox, and: nil)
    }
    
    func givenThereIsAViewModel(withUnifiedInbox: Bool, and account: Account?){
        viewModel = FolderSectionViewModel(account: account, unified: withUnifiedInbox)
    }


    func testNoChildrenOf() {
        viewModel = FolderSectionViewModel(account: account, unified: true)
        let fcvm = FolderCellViewModel(folder: folder, level: 0)

        let numberOfChildren = viewModel.children(of: fcvm).count
        XCTAssert(numberOfChildren == 0)
    }

    func testChildrenOf() {
        let parentFolder = Folder(name: "Parent", parent: nil, account: account, folderType: .inbox)
        self.folder = Folder(name: "Escafoides", parent: parentFolder, account: account, folderType: .normal)
        self.folder.session.commit()

        viewModel = FolderSectionViewModel(account: account, unified: true)

        //Parent
        let parentFCVM = FolderCellViewModel(folder: parentFolder, level: 0)

        let numberOfChildren = viewModel.children(of: parentFCVM).count
        XCTAssert(numberOfChildren == 1)
    }

    func testVisibleChildrenOf() {
        let parentFolder = Folder(name: "Parent", parent: nil, account: account, folderType: .inbox)
        self.folder = Folder(name: "Escafoides", parent: parentFolder, account: account, folderType: .normal)
        self.folder.session.commit()

        viewModel = FolderSectionViewModel(account: account, unified: true)

        //Parent
        let parentFCVM = FolderCellViewModel(folder: parentFolder, level: 0)

        let numberOfChildren = viewModel.visibleChildren(of: parentFCVM).count
        XCTAssert(numberOfChildren == 1)
    }

    func testHiddenChildrenOf() {
        let parentFolder = Folder(name: "Parent", parent: nil, account: account, folderType: .inbox)
        self.folder = Folder(name: "Escafoides", parent: parentFolder, account: account, folderType: .normal)
        self.folder.session.commit()

        viewModel = FolderSectionViewModel(account: account, unified: true)

        //Parent
        let parentFCVM = FolderCellViewModel(folder: parentFolder, level: 0)
        viewModel.visibleChildren(of: parentFCVM).forEach({$0.isHidden = true})
        let numberOfChildren = viewModel.visibleChildren(of: parentFCVM).count
        XCTAssert(numberOfChildren == 0)
    }

    func testIndexOf() {
        let parentFolder = Folder(name: "Parent", parent: nil, account: account, folderType: .inbox)
        self.folder = Folder(name: "Escafoides", parent: parentFolder, account: account, folderType: .normal)
        self.folder.session.commit()

        let account = TestData().createWorkingAccount()
        viewModel = FolderSectionViewModel(account: account, unified: true)

        //Parent
        let parentFCVM = FolderCellViewModel(folder: parentFolder, level: 0)

        //Son
        let sonFCVM = FolderCellViewModel(folder: self.folder, level: 1)

        let index = viewModel.index(of: parentFCVM)
        let sonIndex = viewModel.index(of: sonFCVM)

        XCTAssert(index != NSNotFound)
        XCTAssert(sonIndex != NSNotFound)
        XCTAssert(sonIndex! > index!)
    }
}
