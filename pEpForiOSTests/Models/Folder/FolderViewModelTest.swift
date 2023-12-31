//
//  FolderViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 03/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class FolderViewModelTest: AccountDrivenTestBase {

    var appSettings : AppSettingsProtocol?

    var viewmodel: FolderViewModel!
    var folder: Folder!
    
    struct Input {
        static let maxNumberOfTestAccounts : Int = 2
        static let folderName = "Escafoide"
    }
    override func setUp() {
        super.setUp()
        folder = Folder(name: Input.folderName, parent: nil, account: account, folderType: .inbox)
        folder.session.commit()
    }

    func testFoldersAppearInTheCorrectOrder() {
        //preparing the folder structure
        let acc = givenThereIsAnAccountWithAFolder()
        let _ = Folder(name: "Outbox", parent: nil, account: acc, folderType: .outbox)
        let _ = Folder(name: "Sent", parent: nil, account: acc, folderType: .sent)
        let _ = Folder(name: "Spam", parent: nil, account: acc, folderType: .spam)
        let _ = Folder(name: "Trash", parent: nil, account: acc, folderType: .trash)
        let drafts = Folder(name: "Drafts", parent: nil, account: acc, folderType: .drafts)
        let inbox = acc.rootFolders.first
        let _ = Folder(name: "InsideInbox", parent: inbox, account: acc, folderType: .normal)
        let _ = Folder(name: "InsiDrafts", parent: drafts, account: acc, folderType: .normal)
        let expectedOrder : [FolderType] = [.inbox, .normal, .drafts, .normal, .sent, .spam, .trash, .outbox]

        //the test
        givenThereIsAViewModel(withUniFiedInBox: false, and: [acc])
        let sectionPositionForAccountFolders = 0
        let foldersSection = viewmodel[sectionPositionForAccountFolders]
        XCTAssertEqual(foldersSection.count, acc.totalFolders())
        XCTAssertEqual(foldersSection.count, expectedOrder.count)
        for i in 0..<foldersSection.count {
            guard let folder = foldersSection[i].folder as? Folder else {
                XCTFail()
                return
            }
            XCTAssertEqual(folder.folderType, expectedOrder[i])
        }
    }

    func testNoAccountExistTrueAfterDeleteAccounts() {
        givenThereIsNotAccounts(withUnifiedInbox: false)
        let noAccountsExist = viewmodel.noAccountsExist()
        XCTAssertTrue(noAccountsExist)
    }

    func testSubscript() {
        let accounts = givenThereIs(numberOfAccounts: 1)
        givenThereIsAViewModel(withUniFiedInBox: false, and: accounts)
        let areEqual = viewmodel[0].type == viewmodel.items[0].type && viewmodel[0].count == viewmodel.items[0].count
        XCTAssertTrue(areEqual)
    }

    //MARK: Initialization

    func givenThereIs(numberOfAccounts: Int) -> [Account] {
        if numberOfAccounts > Input.maxNumberOfTestAccounts  || numberOfAccounts < 0 {
            XCTFail("Modify test to have more fake accounts")
        }
        var accounts = [Account]()

        for i in 0..<numberOfAccounts {
            let account = TestData().createWorkingAccount(number: i)
            accounts.append(account)
        }

        return accounts
    }

    func givenThereIsAnAccountWithAFolder() -> Account {
        return account
    }

    func givenThereIsAViewModel(withUniFiedInBox: Bool, and accounts: [Account]){
        viewmodel = FolderViewModel(withFoldersIn: accounts)
    }

    func givenThereIsNotAccounts(withUnifiedInbox: Bool) {
        Account.all().forEach { $0.delete() }
        viewmodel = FolderViewModel(withFoldersIn: nil)
    }

    func testHandleCollapsingSectionStateChanged() {
        let setAccountCollapsedStateExpectation = expectation(description: "setAccountCollapsedStateExpectation")
        let mockAppSettings = MockAppSettings(setAccountCollapsedStateExpectation: setAccountCollapsedStateExpectation)
        let accounts = givenThereIs(numberOfAccounts: 1)
        viewmodel = FolderViewModel(withFoldersIn: accounts, appSettings: mockAppSettings)

        let deleteRowsAtIndexPathsExpectation = expectation(description: "deleteRowsAtIndexPathsExpectation")
        let delegate = MockFolderTableViewController(deleteRowsAtIndexPathsExpectation: deleteRowsAtIndexPathsExpectation)
        viewmodel.delegate = delegate
        viewmodel.handleCollapsingSectionStateChanged(forAccountInSection: 0, isCollapsed: true)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

class MockFolderTableViewController: FolderViewModelDelegate {
    var insertRowsAtIndexPathsExpectation: XCTestExpectation?
    var deleteRowsAtIndexPathsExpectation: XCTestExpectation?

    init(insertRowsAtIndexPathsExpectation: XCTestExpectation? = nil,
         deleteRowsAtIndexPathsExpectation: XCTestExpectation? = nil) {
        self.insertRowsAtIndexPathsExpectation = insertRowsAtIndexPathsExpectation
        self.deleteRowsAtIndexPathsExpectation = deleteRowsAtIndexPathsExpectation
    }

    func insertRowsAtIndexPaths(indexPaths: [IndexPath]) {
        fulfillIfNotNil(expectation: insertRowsAtIndexPathsExpectation)
    }

    func deleteRowsAtIndexPaths(indexPaths: [IndexPath]) {
        fulfillIfNotNil(expectation: deleteRowsAtIndexPathsExpectation)
    }

    private func fulfillIfNotNil(expectation: XCTestExpectation?) {
        if expectation != nil {
            expectation?.fulfill()
        }
    }


}
