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

class FolderViewModelTest: CoreDataDrivenTestBase {

    var viewmodel: FolderViewModel!

    func testAccountSectionsWithUnifiedFolderShouldBeOnePlusAccountNumber() {
        for accountNumber in 0...2 {
            let accounts = givenThereIs(numberOfAccounts: accountNumber)
            givenThereIsAViewModel(withUniFiedInBox: true, and: accounts )

            let viewmodelSections = viewmodel.count

            //If is unified inbox it should have accounts.count + 1 section
            XCTAssertEqual(viewmodelSections, accounts.count + 1)
        }
    }

    func testAccountSectionsWithoutUnifiedFolderShouldBeAccountNumber() {
        for accountNumber in 0...2 {

            let accounts = givenThereIs(numberOfAccounts: accountNumber)
            givenThereIsAViewModel(withUniFiedInBox: false, and: accounts )

            let viewmodelSections = viewmodel.count

            //If it is not unified inbox it should have accounts.count section
            XCTAssertEqual(viewmodelSections, accounts.count)
        }
    }

    //MARK: Initialization

    func givenThereIs(numberOfAccounts: Int) -> [Account] {
        if numberOfAccounts > 2  || numberOfAccounts < 0 {
            XCTFail("Modify test to have more fake accounts")
        }
        var accounts = [Account]()

        for i in 0..<numberOfAccounts {
            let account = SecretTestData().createWorkingAccount(number: i)
            accounts.append(account)
        }

        return accounts
    }

    func givenThereIsAViewModel(withUniFiedInBox: Bool, and accounts: [Account]){
        viewmodel = FolderViewModel(withFoldersIn: accounts, includeUnifiedInbox: withUniFiedInBox)
    }


}
