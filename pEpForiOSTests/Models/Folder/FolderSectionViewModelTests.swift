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

class FolderSectionViewModelTests: CoreDataDrivenTestBase {
    
    var viewModel: FolderSectionViewModel!
    var folder: Folder!
    
    override func setUp() {
        super.setUp()
        self.folder = Folder(name: "Escafoides", parent: nil, account: account, folderType: .inbox)
        self.folder.save()
    }
    
    func testHiddenWhenUnifiedInbox() {
        givenThereIsAViewModelWithAccount(withUnifiedInbox: true)
        XCTAssertTrue(viewModel.hidden)
    }
    
    func testCountIsOneWhenUnifiedInbox() {
        givenThereIsAViewModelWithoutAccount(withUnifiedInbox: true)
        XCTAssertEqual(viewModel.count, 1)
    }
    
    func testNotHiddenWithoutUnifiedInbox() {
        givenThereIsAViewModelWithAccount(withUnifiedInbox: false)
        XCTAssertFalse(viewModel.hidden)
    }
    
    func testUserNameWithAccount() {
        let account = SecretTestData().createWorkingAccount()
        givenThereIsAViewModel(withUnifiedInbox: true, and: account)
        let userName = viewModel.userName
        guard let accountUserName = account.user.userName else {
            XCTFail("No user name in account")
            return
        }
        XCTAssertEqual(userName, accountUserName)
    }
    
    func testUserAddressWithAccount() {
        let account = SecretTestData().createWorkingAccount()
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
        //viewModel = FolderSe
        viewModel = FolderSectionViewModel(account: account, Unified: withUnifiedInbox)
    }
    
    
}
