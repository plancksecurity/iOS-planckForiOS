//
//  FolderViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 03/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
import MessageModel

class FolderViewModelTest: CoreDataDrivenTestBase {

    func testAccountCreation() {
        let viewmodel = FolderViewModel(withFordersIn: [account])
        XCTAssertEqual(viewmodel.count, 2)
    }

    func testAccountCreationWithoutUnified() {
        let viewmodel = FolderViewModel(withFordersIn: [account], includeUnifiedInbox: false)
        XCTAssertEqual(viewmodel.count, 1)
    }
}
